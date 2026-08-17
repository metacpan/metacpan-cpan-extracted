#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use lib 't/lib';
use HMTest qw(free_ports);
use Hyperman;

# TLS session resumption, and SNI selection across a map big enough that the
# lookup has to actually search.
#
# The resumption half exists because the ticket key is easy to break in a way
# nothing else notices: every certificate rotation still works, every request
# still succeeds, and the only symptom is that resumption silently stops
# happening and every client pays a full handshake. It has already been broken
# twice - once because each SSL_CTX minted its own random key, and once
# because the length the key is fetched with is 48 bytes on OpenSSL 1.1.1 and
# 80 on 3.x, and asking with the wrong one makes the ctrl a no-op that returns
# 0 with nothing logged.

plan skip_all => 'OpenSSL support not built' unless Hyperman->has_tls;
my $openssl = `which openssl`; chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $made = 1;
sub sh { $made &&= system("$_[0] >/dev/null 2>&1") == 0 }

my @hosts = qw(alpha.test bravo.test charlie.test delta.test echo.test
               foxtrot.test golf.test hotel.test india.test juliet.test);
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/srv.key -out $dir/srv.pem -days 1 -subj "/CN=localhost"});
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/late.key -out $dir/late.pem -days 1 -subj "/CN=late.test"});
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/$_.key -out $dir/$_.pem -days 1 -subj "/CN=$_"})
    for @hosts;
plan skip_all => 'could not create the test certificates'
    unless $made && !grep { !-s "$dir/$_.pem" } ('srv', 'late', @hosts);

my ($port) = free_ports(1);
plan skip_all => 'could not get a free port' unless $port;

my %sni = map { $_ => { cert => "$dir/$_.pem", key => "$dir/$_.key" } } @hosts;

my $pid = fork // plan skip_all => 'cannot fork';
if (!$pid) {
    Hyperman->run(
        app => sub {
            my $env = shift;
            if ($env->{PATH_INFO} eq '/reload') {
                my $n = Hyperman->tls_reload({
                    %sni,
                    'late.test' => { cert => "$dir/late.pem", key => "$dir/late.key" },
                });
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ "reloaded=$n" ] ];
            }
            [ 200, [ 'Content-Type' => 'text/plain' ],
              [ "https=" . ($env->{HTTPS} // '-')
              . " proto=" . ($env->{SSL_PROTOCOL} // '-')
              . " cipher=" . ($env->{SSL_CIPHER} // '-')
              . " verify=" . ($env->{SSL_CLIENT_VERIFY} // '-') ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
        tls_cert => "$dir/srv.pem", tls_key => "$dir/srv.key",
        tls_sni  => \%sni,
    );
    exit 0;
}
for (1 .. 200) {
    last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port", Timeout => 1);
    Time::HiRes::sleep(0.05);
}

# A TLS 1.3 ticket arrives after the handshake, so s_client has to drive a
# real request AND outlive its own stdin to see one. Without -ign_eof it
# sends close_notify the moment the piped request ends and writes no session
# file at all - openssl's own s_server behaves the same way, so this is
# s_client's doing and not the server's.
sub req {
    my ($host, $path, @args) = @_;
    return `printf 'GET $path HTTP/1.0\r\n\r\n' | openssl s_client -connect 127.0.0.1:$port -servername $host -ign_eof @args 2>&1`;
}
sub sess { my ($host, @args) = @_; return req($host, '/', @args) }

# ---- SNI: every host in the map is found, whatever its position ----
for my $h (@hosts) {
    like(sess($h), qr/CN\s*=\s*\Q$h\E/, "SNI: $h serves its own certificate");
}
like(sess('ALPHA.TEST'), qr/CN\s*=\s*alpha\.test/,
     'SNI: an uppercase servername still matches (names are case-insensitive)');
like(sess('nope.test'), qr/CN\s*=\s*localhost/,
     'SNI: a host not in the map falls back to the default certificate');

# ---- the $env keys ----
{
    my $out = sess('alpha.test');
    like($out, qr/https=on/,          'env: HTTPS is on');
    like($out, qr/proto=TLSv1\.[23]/, 'env: SSL_PROTOCOL is set');
    like($out, qr/cipher=\S/,         'env: SSL_CIPHER is set');
    like($out, qr/verify=NONE/,       'env: SSL_CLIENT_VERIFY is NONE without a client cert');
}

# ---- session resumption ----
# LibreSSL (OpenBSD base, macOS's CLI) implements no TLS 1.3 session
# resumption on either side of the connection: its server never sends a
# NewSessionTicket and its s_client never stores one, so under 1.3 these
# checks can never pass however correct the ticket key is. The key
# machinery this file guards is protocol-independent, so on a LibreSSL
# stack - the linked library or the CLI, either breaks it - the resumption
# half runs over TLS 1.2, where LibreSSL's tickets work. Detected by
# identity rather than probed, deliberately: a functional fallback would
# also hide a real OpenSSL regression that stopped 1.3 tickets.
my $cli   = `openssl version 2>/dev/null` // ''; chomp $cli;
my $stack = (Hyperman->tls_library // '') . ' ' . $cli;
my @resume_proto = $stack =~ /LibreSSL/i ? ('-tls1_2') : ();
diag("resumption tested over TLS 1.2: LibreSSL in play ($stack)")
    if @resume_proto;

sub resumes {
    my ($host, $file) = @_;
    unlink $file;
    sess($host, @resume_proto, '-sess_out', $file);
    return 0 unless -s $file;
    return sess($host, @resume_proto, '-sess_in', $file) =~ /Reused/ ? 1 : 0;
}
ok(resumes('alpha.test', "$dir/s1.pem"), 'a session resumes');

# ---- and it survives a certificate rotation ----
# This is the one that matters on a fleet: tls_reload runs independently in
# every worker, and SSL_CTX_new mints a fresh random ticket key, so unless
# the running context's key is carried into the new one a ticket stops being
# decryptable the moment anything rotates.
unlink "$dir/pre.pem";
sess('alpha.test', @resume_proto, '-sess_out', "$dir/pre.pem");
ok(-s "$dir/pre.pem", 'got a ticket before the reload');

like(req('alpha.test', '/reload'), qr/reloaded=1/, 'tls_reload rebuilt the listener');

like(sess('alpha.test', @resume_proto, '-sess_in', "$dir/pre.pem"), qr/Reused/,
     'a ticket issued before tls_reload still resumes after it');
ok(resumes('alpha.test', "$dir/s2.pem"), 'new sessions still resume after tls_reload');
like(sess('late.test'), qr/CN\s*=\s*late\.test/,
     'reload: the host added by the reload serves its own certificate');

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
