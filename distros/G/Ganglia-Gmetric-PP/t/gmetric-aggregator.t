use strict;
use warnings;

use Test::More;

use Ganglia::Gmetric::PP;
use IO::Socket::INET;
use Time::HiRes 'time';

my $aggregator_bin = "blib/script/gmetric-aggregator.pl";
my $aggregation_period = 5;

my @types = qw/ float double int8 uint8 int16 uint16 int32 uint32 /;

unless (eval "use AnyEvent; 1" || eval "use Danga::Socket; 1") {
    plan skip_all => 'Need AnyEvent or Danga::Socket';
    exit;
}

plan(tests => 2 * scalar @types);

$SIG{ALRM} = sub {
    die "test timeout hit\n";
};
alarm 20;

for my $should_upgrade_types (0, 1) {

    my $gmond = Ganglia::Gmetric::PP->new(listen_host => 'localhost', listen_port => 0);
    my $gmond_port = $gmond->sockport;

    my $listen_sock = IO::Socket::INET->new(
        Type      => SOCK_STREAM,
        Proto     => 'tcp',
        Reuse     => 1,
        Listen    => 1,
    );
    my $proxy_port = $listen_sock->sockport;
    $listen_sock->close;

    # start proxy
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        $ENV{PERL5LIB} = join ':', @INC;
        exec
            $aggregator_bin,
            '--pp-client',
            '--remote-host'     => 'localhost',
            '--remote-port'     => $gmond_port,
            '--listen-host'     => 'localhost',
            '--listen-port'     => $proxy_port,
            '--period'          => $aggregation_period,
            '--metric-suffix'   => '',
            $should_upgrade_types ? '--floating' : '--no-floating',
        ;
        die "exec failed: $!";
    }

    # allow aggregator to start up
    sleep 1;

    my $gmetric = Ganglia::Gmetric::PP->new(host => 'localhost', port => $proxy_port);

    my $start_time = time;

    my %sums;
    for my $type (@types) {
        my $name = "${type}test";

        for (1..10) {
            my $value = rand 100;
            $value = int $value if $type =~ /int/;
            my $sent = $gmetric->send($type, $name, $value, 'things');
            $sums{$name} += $value;
        }
    }

    for (@types) {
        my $found = wait_for_readable($gmond);
        die "can't read from self" unless $found;

        my $end_time = time;
        my $duration = $end_time - $start_time;

        my ($type, $name, $value) = $gmond->receive;

        my $expected = $sums{$name} / $duration;
        my $deviation = abs($value - $expected) / $expected;

        ok($deviation < 1/$aggregation_period, $name); # allow for a second or so of difference
    }

    kill 'INT', $pid;
    waitpid $pid, 0;
}

sub wait_for_readable {
    my $sock = shift;
    vec(my $rin = '', fileno($sock), 1) = 1;
    return select(my $rout = $rin, undef, undef, 7);
}
