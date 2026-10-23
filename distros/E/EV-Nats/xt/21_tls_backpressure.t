use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use File::Temp qw(tempdir);
use POSIX ();
use EV;
use EV::Nats;

plan skip_all => 'EV::Nats built without TLS' unless EV::Nats::HAS_TLS();
my $bin = nats_bin_or_skip();
my $dir = tempdir(CLEANUP => 1);
my $port = free_port();
my $cert_pid = fork;
die "fork: $!" unless defined $cert_pid;
if (!$cert_pid) {
    open STDOUT, '>', "$dir/openssl.log" or die $!;
    open STDERR, '>&', STDOUT or die $!;
    { exec 'openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
        '-subj', '/CN=localhost', '-addext', 'subjectAltName=IP:127.0.0.1',
        '-keyout', "$dir/key.pem", '-out', "$dir/cert.pem"; }
    require POSIX;
    POSIX::_exit(1);
}
my $cert_ok;
{ local $?; waitpid $cert_pid, 0; $cert_ok = !$?; }
plan skip_all => 'openssl certificate generation unavailable' unless $cert_ok;

open my $conf, '>', "$dir/nats.conf" or die $!;
print $conf "host: 127.0.0.1\nport: $port\ntls {\n",
    "cert_file: \"$dir/cert.pem\"\nkey_file: \"$dir/key.pem\"\n}\n";
close $conf;
my $pid = spawn_nats($bin, '-c', "$dir/nats.conf");
END {
    if ($pid) { local $?; kill 'CONT', $pid; kill 'TERM', $pid; waitpid $pid, 0; }
}

plan tests => 5;
my ($nats, $later, $flushed, @errors);
my ($received, $intact) = (0, 1);
my $payload = 'x' x (256 * 1024);
$nats = EV::Nats->new(
    host => '127.0.0.1', port => $port, tls => 1, tls_ca_file => "$dir/cert.pem",
    on_error => sub { push @errors, $_[0]; EV::break },
    on_connect => sub {
        $nats->subscribe('tls.bulk', sub {
            $received++;
            $intact &&= $_[1] eq $payload;
        });
        kill 'STOP', $pid;
        $nats->publish('tls.bulk', $payload) for 1..40;
        # Grow the buffer while the first TLS write is stalled on the socket.
        $later = EV::timer(0.1, 0, sub {
            undef $later;
            $nats->publish('tls.bulk', $payload) for 1..40;
            kill 'CONT', $pid;
            $nats->flush(sub { $flushed = !defined $_[0]; EV::break });
        });
    },
);
my $guard = EV::timer(15, 0, sub { kill 'CONT', $pid; EV::break });
EV::run;
kill 'CONT', $pid;
is_deeply \@errors, [], 'TLS write survives buffer growth under backpressure';
ok $flushed, 'all buffered writes reached the server';
is $received, 80, 'every publish delivered exactly once';
ok $intact, 'payloads survived TLS write retries';
$nats->disconnect;

pipe(my $ready_rd, my $ready_wr) or die $!;
pipe(my $closed_rd, my $closed_wr) or die $!;
my $client_pid = fork;
die "fork: $!" unless defined $client_pid;
if (!$client_pid) {
    close $ready_rd;
    close $closed_wr;
    $SIG{PIPE} = 'DEFAULT';
    alarm 10;
    my $loop = EV::Loop->new;
    my ($client, $error);
    $client = EV::Nats->new(
        loop => $loop, host => '127.0.0.1', port => $port,
        tls => 1, tls_ca_file => "$dir/cert.pem",
        on_connect => sub { $loop->break },
        on_error => sub { $error = $_[0]; $loop->break },
    );
    my $guard = $loop->timer(3, 0, sub { $loop->break });
    $loop->run;
    print $ready_wr "ready\n";
    close $ready_wr;
    <$closed_rd>;
    for (1..3) {
        last unless $client->is_connected;
        $client->flush;
        select undef, undef, undef, 0.1;
    }
    POSIX::_exit(defined($error) && !$client->is_connected ? 0 : 1);
}
close $ready_wr;
close $closed_rd;
<$ready_rd>;
close $ready_rd;
{ local $?; kill 'KILL', $pid; waitpid $pid, 0; undef $pid; }
{ local $SIG{PIPE} = 'IGNORE'; print $closed_wr "closed\n"; close $closed_wr; }
my $status;
{ local $?; waitpid $client_pid, 0; $status = $?; }
is $status, 0, 'TLS peer shutdown reports a write error without SIGPIPE';
