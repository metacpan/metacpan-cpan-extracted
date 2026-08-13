#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# The fast default access-log writer: access_log => $path formats a Combined
# Log Format line in C (no per-request Perl call) and appends to the file,
# shared O_APPEND across workers. Also checks REMOTE_ADDR reaches the env.

my $dir     = File::Temp::tempdir(CLEANUP => 1);
my $logfile = "$dir/access.log";
my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    open STDERR, '>', '/dev/null';
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $body = join ';',
                "remote=" . ($env->{REMOTE_ADDR} // '?'),
                "host="   . ($env->{REMOTE_HOST} // '?'),
                "port="   . (($env->{REMOTE_PORT} // 0) > 0 ? 'ok' : 'bad'),
                "buffered=" . ($env->{'psgix.input.buffered'} ? 1 : 0);
            [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
        },
        access_log => $logfile,           # <-- fast C writer, not a coderef
        host       => '127.0.0.1',
        port       => $port,
        workers    => 1,
    );
    exit 0;
}

sub get {
    my ($path, %opt) = @_;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        my $req = "GET $path HTTP/1.0\r\n";
        $req .= "User-Agent: $opt{ua}\r\n" if defined $opt{ua};
        $req .= "Referer: $opt{ref}\r\n"   if defined $opt{ref};
        $req .= "\r\n";
        $s->print($req);
        # bounded read: a peer that accepts and then says nothing must not
        # wedge the test file for the harness's whole timeout.
        my $r = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
            local $/;
            my $body = <$s>;
            alarm 0;
            $body;
        };
        alarm 0;
        return $1 if defined $r && $r =~ /\r\n\r\n(.*)\z/s;
        Time::HiRes::sleep(0.1);
    }
    return undef;
}

sub slurp_log {
    open my $fh, '<', $logfile or return '';
    local $/;
    return scalar <$fh>;
}

# wait for the server to come up and confirm the peer/env fields made it in
my $body = get('/hello');
like($body, qr/\bremote=127\.0\.0\.1\b/,   'REMOTE_ADDR populated in the PSGI env')
    or diag "body was: " . (defined $body ? $body : '(undef)');
like($body, qr/\bhost=127\.0\.0\.1\b/,     'REMOTE_HOST populated');
like($body, qr/\bport=ok\b/,               'REMOTE_PORT populated (peer port)');
like($body, qr/\bbuffered=1\b/,            'psgix.input.buffered set (seekable :scalar input)');

# a request with recognizable Referer / User-Agent to check the quoted fields
get('/track?x=1', ua => 'AcmeBot/2.0', ref => 'http://ref.example/');

# the writer flushes once per loop wakeup; poll briefly for the lines
my $log = '';
for (1 .. 30) {
    $log = slurp_log();
    last if $log =~ m{/track};
    Time::HiRes::sleep(0.1);
}

like(
    $log,
    qr{^127\.0\.0\.1 - - \[[^\]]+\] "GET /hello HTTP/1\.0" 200 \d+ "-" "-"$}m,
    'Combined Log Format line for the plain request',
) or diag "log:\n$log";

like(
    $log,
    qr{^127\.0\.0\.1 - - \[[^\]]+\] "GET /track\?x=1 HTTP/1\.0" 200 \d+ "http://ref\.example/" "AcmeBot/2\.0"$}m,
    'Combined line carries the request URI, Referer and User-Agent',
) or diag "log:\n$log";

# the timestamp field is apache-style: [dd/Mon/YYYY:HH:MM:SS +ZZZZ]
like(
    $log,
    qr{\[\d\d/[A-Z][a-z]{2}/\d{4}:\d\d:\d\d:\d\d [-+]\d{4}\]},
    'timestamp is in Common/Combined Log Format',
);

kill 'TERM', $sup;
waitpid $sup, 0;

done_testing;
