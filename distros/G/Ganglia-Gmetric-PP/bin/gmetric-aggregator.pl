#! /usr/bin/perl

# gmetric proxy which consumes metric samples consisting of absolute values and
# re-emits time-aggregated rate metrics to gmond instead

use strict;
use warnings;

use Data::Dumper ();
use Ganglia::Gmetric::PP ':all';
use Getopt::Long 'GetOptions';
use Time::HiRes 'time';

sub usage {
    (my $me = $0) =~ s,.*/,,;
    my $error = shift;
    print "Error: $error\n\n" if $error;
    print <<EOU;
$me $Ganglia::Gmetric::PP::VERSION

Usage: $me [OPTIONS]...

  --[no-]pp-client           Use Ganglia::Gmetric::PP for talking to gmond.
                             Default off, which requires a working gmetric
                             (see --gmetric below)

  -h, --remote-host=STRING   Remote host where gmond is running. Default localhost
  -p, --remote-port=INT      Remote port where gmond is running. Default 8649

      --gmetric=PATH         Path to gmetric(1) binary. -h and -p options are
                             ignored; gmetric usse its own gmond.conf for host
                             settings.

  -H, --listen-host=STRING   Local interface to listen on. Default 0.0.0.0
  -P, --listen-port=INT      Local UDP port to listen on. Default 18649
  -u, --unit-suffix=STRING   Suffix to append to gmetric units. Default "/s"
  -m, --metric-suffix=STRING Suffix to append to metric names. Default "_rate"
  -n, --period=INT           Time period in seconds between aggregations. Default 60

  -N, --multiplier=FLOAT     Amount to multiply output values by. Default 1
                             (e.g., use "-N 3600 -u /hour" to emit per-hour
                             metrics).

  -f, --[no]-floating        Always use "double" type instead of original metrics'
                             types. Default on

  -d, --daemon               Run in daemon mode.
  -U, --user                 User to drop to (only if started as root)
  -F, --pidfile=FILE         File to write PID to in daemon mode.
  -g, --debug                Display debugging output
  --help                     Print help and exit
EOU
    exit 1;
}

Getopt::Long::Configure('no_ignore_case');
GetOptions(
    'pp-client!'        => \(my $use_pp_client  = 0),
    'h|remote-host=s'   => \(my $remote_host    = '127.0.0.1'),
    'p|remote-port=i'   => \(my $remote_port    = 8649),
    'gmetric=s'         => \(my $gmetric),
    'H|listen-host=s'   => \(my $listen_host    = '0.0.0.0'),
    'P|listen-port=i'   => \(my $listen_port    = 18649),
    'u|unit-suffix=s'   => \(my $units_suffix   = '/s'),
    'm|metric-suffix=s' => \(my $metric_suffix  = '_rate'),
    'n|period=i'        => \(my $period         = 60),
    'N|multiplier=i'    => \(my $multiplier     = 1.0),
    'f|floating!'       => \(my $output_doubles = 1),
    'd|daemon!'         => \(my $daemonize),
    'U|user=s'          => \(my $user),
    'F|pidfile=s'       => \(my $pidfile),
    'g|debug'           => \(my $debug),
    'help!'             => \(my $help),
) || usage;

my $emitter;
if ($use_pp_client) {
    $emitter = Ganglia::Gmetric::PP->new(
        host => $remote_host,
        port => $remote_port,
    );
}
else {
    unless ($gmetric) {
        $gmetric = qx(which gmetric);
        die "can't find gmetric\n" unless $gmetric;
        chomp $gmetric;
    }
    die "can't run gmetric\n" unless -x $gmetric;
}

usage if $help;

my $use_anyevent;
if (eval "use AnyEvent; 1") {
    $debug && warn "Using AnyEvent\n";
    $use_anyevent = 1;
}
elsif (eval "use Danga::Socket; 1") {
    $debug && warn "Using Danga::Socket\n";
    $use_anyevent = 0;
}
else {
    die "need either AnyEvent or Danga::Socket module";
}

if ($daemonize) {
    die "Proc::Daemon not available" unless eval "use Proc::Daemon (); 1";
    Proc::Daemon::Init();
}

if ($pidfile && open my $pid_fh, '>', $pidfile) {
    print $pid_fh "$$\n";
    close $pid_fh;
}
END { unlink $pidfile if $pidfile }

# udp server socket
my $gmond = Ganglia::Gmetric::PP->new(listen_host => $listen_host, listen_port => $listen_port);

if (defined $user) {
    die "POSIX not available" unless eval "use POSIX (); 1";
    my ($uid, $gid) = (getpwnam $user)[2, 3];
    die "couldn't find uid/gid for user $user" unless defined $uid && defined $gid;
    $debug && warn "Dropping to uid=$uid/gid=$gid\n";
    POSIX::setgid($gid) or die "failed to set gid to $gid: $!";
    POSIX::setuid($uid) or die "failed to set uid to $uid: $!";
}

# can only aggregate numeric types
my %allowed_types = map {$_ => 1} qw/ double float int8 int16 int32 uint8 uint16 uint32 /;

my $last_time;

# store gmetric events as they are received
my %metric_aggregates;
my %metric_templates;
sub handle {
    # receive and parse packet
    my @sample;
    eval { @sample = $gmond->receive };
    return unless @sample;
    return unless $allowed_types{ $sample[METRIC_INDEX_TYPE] };

    # start counting at receipt of first event
    $last_time ||= time;

    # aggregate sums on the fly
    $metric_aggregates{ $sample[METRIC_INDEX_NAME] } += $sample[METRIC_INDEX_VALUE];

    # keep an example copy of this metric to re-emit with aggregated values
    $metric_templates{ $sample[METRIC_INDEX_NAME] } ||= \@sample;

    $debug && warn Data::Dumper->Dump([\@sample], ['sample']);
}
my $watcher;
if ($use_anyevent) {
    $watcher = AnyEvent->io(fh => $gmond, poll => 'r', cb => \&handle);
}
else {
    Danga::Socket->AddOtherFds(fileno($gmond), \&handle);
}

$SIG{CHLD} = 'IGNORE';

# periodically aggregate collected samples and re-emit to target gmond
my $timer;
sub aggregator {
    if ($last_time) {
        my $time = time;
        my $measured_period = $time - $last_time;
        $debug && warn "Aggregating at $time ($measured_period elapsed)\n";

        # emit for any metric seen before, even if it wasn't seen in the last period
        for my $metric (keys %metric_templates) {
            my @aggregate = @{ $metric_templates{$metric} };

            # aggregated value is rate of metric over last period
            $aggregate[METRIC_INDEX_VALUE] = ($metric_aggregates{$metric}||0) / ($measured_period||1);

            if ($output_doubles) {
                $aggregate[METRIC_INDEX_TYPE] = GANGLIA_VALUE_DOUBLE;
            }
            elsif ($aggregate[METRIC_INDEX_TYPE] =~ /int/) {
                $aggregate[METRIC_INDEX_VALUE] = int($aggregate[METRIC_INDEX_VALUE])
            }

            $aggregate[METRIC_INDEX_NAME]  .= $metric_suffix;
            $aggregate[METRIC_INDEX_UNITS] .= $units_suffix;
            $aggregate[METRIC_INDEX_VALUE] *= $multiplier;
            $aggregate[METRIC_INDEX_TMAX] = $period;

            if ($use_pp_client) {
                $emitter->send(@aggregate);
            }
            else {
                my $pid = fork;
                if (!defined $pid) {
                    warn "fork failed: $!";
                    return;
                }
                elsif (!$pid) {
                    my %gmetric_args;
                    @gmetric_args{qw/ --type --name --value --units --slope --tmax --dmax /} = @aggregate;
                    $debug && warn "Running $gmetric @{[%gmetric_args]}\n";
                    exec $gmetric, %gmetric_args;
                    die "exec failed: $!\n";
                }
            }

            $debug && warn Data::Dumper->Dump([\@aggregate], [$metric]);
        }
        %metric_aggregates = ();

        $last_time = $time;
    }

    if ($use_anyevent) {
        $timer = AnyEvent->timer(after => $period, cb => \&aggregator);
    }
    else {
        Danga::Socket->AddTimer($period, \&aggregator);
    }
}

# run event loop
if ($use_anyevent) {
    $timer = AnyEvent->timer(after => $period, cb => \&aggregator);
    AnyEvent->condvar->recv;
}
else {
    Danga::Socket->AddTimer($period, \&aggregator);
    Danga::Socket->EventLoop;
}
