#!perl
use 5.008003;
use strict;
use warnings;
no warnings 'once';   # $IO::Socket::SSL::SSL_ERROR is referenced once
use File::Temp ();
use Test::More;
use Fetch;

# Requires OpenSSL in the Fetch build and IO::Socket::SSL + openssl(1) for the
# throwaway server/cert. Skip cleanly otherwise.
plan skip_all => 'Fetch built without OpenSSL'  unless Fetch::_tls_available();
plan skip_all => 'IO::Socket::SSL not installed'
    unless eval { require IO::Socket::SSL; 1 };

my $dir  = File::Temp->newdir;
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
my $rc = system("openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert "
              . "-days 1 -nodes -subj /CN=localhost >/dev/null 2>&1");
plan skip_all => 'openssl(1) not available to make a test cert' if $rc != 0;

my $srv = IO::Socket::SSL->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1,
    SSL_cert_file => $cert, SSL_key_file => $key,
) or plan skip_all => "cannot start TLS server: "
    . ($IO::Socket::SSL::SSL_ERROR || 'unknown');
my $port = $srv->sockport;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    while (my $c = $srv->accept) {
        my $l = <$c>; my ($path) = $l =~ m{^\S+\s+(\S+)};
        while (my $h = <$c>) { last if $h eq "\r\n" }
        my $b = "secure:$path";
        print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
               . "Content-Length: " . length($b) . "\r\nConnection: close\r\n\r\n$b";
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.3);

plan tests => 5;

my $ua   = Fetch->new;
my $base = "https://127.0.0.1:$port";

# ---- https GET with verification disabled (self-signed) ------------------
{
    my $res = $ua->get("$base/hi", tls_verify => 0)->get;
    is($res->status, 200, 'https GET status 200');
    is($res->content, 'secure:/hi', 'https body decrypted correctly');
}

# ---- concurrent TLS requests multiplex on one loop -----------------------
{
    my @f = map { $ua->get("$base/c$_", tls_verify => 0) } 1 .. 5;
    Fetch::Future->needs_all(@f)->get;
    is_deeply([map { $_->get->status } @f], [ (200) x 5 ],
        'five concurrent TLS requests all 200');
    like(($f[2]->get)->content, qr{secure:/c3}, 'concurrent TLS not crossed');
}

# ---- verification against a self-signed cert must fail -------------------
{
    my $f = $ua->get("$base/hi", tls_verify => 1);
    eval { $f->get };   # pumps the loop; croaks because the cert is self-signed
    ok($f->is_failed, 'tls_verify=1 rejects a self-signed cert');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
