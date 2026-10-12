#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports free_ports6 quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# IPv6 listeners: a server on ::1 answers an IPv6 client and reports its
# address; :: and 0.0.0.0 bind together on one port; a host that does not
# resolve is refused before anything is bound; the Plack handler parses the
# bracketed spelling.

plan skip_all => 'IO::Socket::IP is needed to speak IPv6 from the test'
    unless eval { require IO::Socket::IP; 1 };
my ($p6, $pdual) = free_ports6(2);
plan skip_all => 'no usable IPv6 loopback on this box' unless $p6 && $pdual;
my $dir = File::Temp::tempdir(CLEANUP => 1);

my $app = sub {
    my $env = shift;
    [ 200, [ 'Content-Type' => 'text/plain' ],
      [ join '|', $env->{REMOTE_ADDR} // 'none', $env->{SERVER_NAME} // 'none',
                  $env->{REMOTE_PORT} ? 'port' : 'noport' ] ];
};

my %kids;
sub spawn {
    my (%opt) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        Hyperman->run(app => $app, workers => 1, %opt);
        exit 0;
    }
    $kids{$pid} = 1;
    return $pid;
}

sub get {
    my ($host, $port) = @_;
    my $s;
    for (1 .. 50) {
        $s = IO::Socket::IP->new(PeerHost => $host, PeerPort => $port, Proto => 'tcp') and last;
        Time::HiRes::sleep(0.1);
    }
    return '' unless $s;
    $s->syswrite("GET / HTTP/1.0\r\n\r\n");
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    close $s;
    return $buf =~ /\r\n\r\n(.*)\z/s ? $1 : '';
}

# ---- a listener on ::1 -------------------------------------------------------
{
    spawn(host => '::1', port => $p6);
    is get('::1', $p6), '::1|::1|port', 'an IPv6 client is served and REMOTE_ADDR is ::1';
}

# ---- :: and 0.0.0.0 on one port --------------------------------------------
{
    spawn(listen => [ { host => '0.0.0.0', port => $pdual }, { host => '::', port => $pdual } ]);
    like get('127.0.0.1', $pdual), qr/\A127\.0\.0\.1\|0\.0\.0\.0\|port\z/, 'the v4 listener of the pair answers';
    like get('::1', $pdual), qr/\A::1\|::\|port\z/, 'the v6 listener of the pair answers';
}

# ---- an unresolvable host is refused with nothing bound --------------------
SKIP: {
    my $bad = ('x' x 64) . '.invalid';
    skip 'this resolver answers a name that cannot exist', 3 if defined gethostbyname($bad);
    my ($pbad) = free_ports(1);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDERR, '>', "$dir/bad.err";
        open STDOUT, '>', '/dev/null';
        eval { Hyperman->run(app => $app, workers => 1, host => $bad, port => $pbad) };
        print STDERR "CROAK: $@" if $@;
        exit 3;
    }
    waitpid $pid, 0;
    is $? >> 8, 3, 'run() croaked on a host that does not resolve';
    open my $fh, '<', "$dir/bad.err"; local $/; my $e = <$fh> // '';
    like $e, qr/listen host '\Q$bad\E':/, '...naming the host';
    my $probe = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $pbad,
                                      Proto => 'tcp', Listen => 1, ReuseAddr => 1);
    ok $probe, '...and the port was never bound on any interface';
    close $probe if $probe;
}

# ---- the Plack handler's bracketed spelling ---------------------------------
SKIP: {
    skip 'Plack::Handler::Hyperman needs Plack', 2
        unless eval { require Plack::Handler::Hyperman; 1 };
    is_deeply Plack::Handler::Hyperman::_parse_listen('[::1]:8080'),
        { host => '::1', port => 8080 }, '[::1]:8080 parses';
    is_deeply Plack::Handler::Hyperman::_parse_listen('127.0.0.1:8080'),
        { host => '127.0.0.1', port => 8080 }, 'the v4 spelling still parses';
}

kill 'TERM', $_ for keys %kids;
waitpid $_, 0 for keys %kids;
done_testing;
