#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/05_GnuPlot.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

my @warnings;
$SIG{__WARN__} = sub { push @warnings, shift };
sub check_warnings {
    is(@warnings, 0, "No warnings");
    if (@warnings) {
        diag("Unexpected warnings:");
        diag($_) for @warnings;
    }
    @warnings = ();
}

END {
    check_warnings;
};

my $MIN_VERSION = 3.7;
$ENV{SHELL} = "/bin/false";

use File::Temp qw(tempfile);

BEGIN { use_ok('Graph::Layout::Aesthetic::Monitor::GnuPlot') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };
BEGIN { use_ok('Graph::Layout::Aesthetic') };

my ($tmp, $curpos, $have);
my $MAX_WAIT = 10;
sub tail {
    my $target = shift;
    my $start = time;
    until (ref($target) ? $have =~ s/^$target// : $have =~ s/^\Q$target//) {
        local $_;
        seek($tmp, $curpos, 0) || die "Seek error: $!";
        $have .= $_ while <$tmp>;
        $curpos = tell($tmp);
        my $now = time;
        if (!ref($target) && $target !~ /^\Q$have/ ||
            $now > $start + $MAX_WAIT) {
            diag("Could not find '$target' in '$have'");
            fail(@_ ? shift : ());
            return;
        }
        sleep 1 if $now > $start+1;
    }
    pass(@_ ? shift : ());
}

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(4);
$topo->add_edge(0, 1);
$topo->add_edge(1, 2);
$topo->add_edge(2, 3);
$topo->add_edge(3, 0);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinEdgeLength");

{
    local @Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot = qw(/);
    if ($^O ne "MSWin32") {
        eval { Graph::Layout::Aesthetic::Monitor::GnuPlot->new };
        like($@, qr!^Could not start /: !, "/ isn't executable");
    }

    (my $fh, my $tmp_name) = tempfile(UNLINK => 1);
    open($tmp, "<", $tmp_name) || die "Could not open $tmp_name: $!";
    @Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot =
        ($^X, "t/tofile.pl", $tmp_name);
    $curpos = 0;
    $have = "";
    my $monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new;
    is($monitor->last_plot_time, undef, "No plots yet");
    my $terminal = $^O eq "MSWin32" ? "windows" : "X11";
    tail("set terminal $terminal
set data style linespoints
set offsets 0.1, 0.1, 0.1, 0.1
set nokey
set clip two
", "Proper initialization");
    $aglo->all_coordinates([0, 0], [1, 1], [0, 1], [1, 0]);
    $monitor->plot($aglo);
    tail(qr!set xrange \[ -0.050* : 1.050* \]
set yrange \[ -0.050* : 1.050* \]
set title "Time=\d+\s+Temp=100.0*"
plot "-"
0 0
1 1

1 1
0 1

0 1
1 0

1 0
0 0

e
!, "Proper plot commands");
    my $from = time;
    $aglo->gloss(iterations	=> 1,
                 hold		=> 1,
                 monitor	=> $monitor,
                 monitor_delay	=> 0);
    tail(qr!set xrange \[ -0.050* : 1.050* \]
set yrange \[ -0.050* : 1.050* \]
set title "Time=\d+\s+Temp=100.0*"
plot "-"
0 0
1 1

1 1
0 1

0 1
1 0

1 0
0 0

e
set xrange \[ -1.6056\d+ : 2.6056\d+ \]
set yrange \[ -1.6056\d+ : 2.6056\d+ \]
set title "Time=\d+    Temp=0.001"
plot "-"
2.414\d+ 1.414\d+
-1.414\d+ -0.414\d+

-1.414\d+ -0.414\d+
2.414\d+ -0.414\d+

2.414\d+ -0.414\d+
-1.414\d+ 1.414\d+

-1.414\d+ 1.414\d+
2.414\d+ 1.414\d+

e
!);
    my $to = time;
    my $last_time = $monitor->last_plot_time;
    ok($from <= $last_time, "Time goes forward");
    ok($to   >= $last_time, "Time goes forward");
    $monitor->command("foo");
    $monitor->commandf("%s %d", "baz", 12.3);
    $monitor->command_flush("bar");
    tail("foo\nbaz 12\nbar\n");
    $monitor = undef;
    tail("quit\n");

    my $plot_count = 0;
    $monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new
        (after_plot => sub { $plot_count++ });
    is($plot_count, 0);
    $monitor->plot($aglo);
    is($plot_count, 1);
    $monitor->plot($aglo);
    is($plot_count, 2);
    $monitor = undef;
    is($plot_count, 2);

    $tmp = undef;
    $fh  = undef;

    # Start a new monitor log
    ($fh, $tmp_name) = tempfile(UNLINK => 1);
    open($tmp, "<", $tmp_name) || die "Could not open $tmp_name: $!";
    @Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot =
        ($^X, "t/tofile.pl", $tmp_name);
    $curpos = 0;
    $have = "";
    $monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new;

    my $aglo = Graph::Layout::Aesthetic->new($topo, 3);
    $aglo->all_coordinates([1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]);
    $monitor->plot($aglo);
    tail(qr!set terminal $terminal
set data style linespoints
set offsets 0.1, 0.1, 0.1, 0.1
set nokey
set clip two
set xrange \[ 0.550* : 10.450* \]
set yrange \[ 1.550* : 11.450* \]
set zrange \[ 2.550* : 12.450* \]
set title "Time=\d+\s+Temp=100.0*"
plot "-"
1 2 3
4 5 6

4 5 6
7 8 9

7 8 9
10 11 12

10 11 12
1 2 3

e
!);

    # Can't monitor < 2 dim
    $aglo = Graph::Layout::Aesthetic->new($topo, 1);
    $aglo->zero;
    eval { $monitor->plot($aglo) };
    like($@, qr!^Space is 1-dimensional \(gnuplot display only work in 2 or 3 dimensions\) at !, "Dimemsion check");

    # Can't monitor > 3 dim
    $aglo = Graph::Layout::Aesthetic->new($topo, 4);
    $aglo->zero;
    eval { $monitor->plot($aglo) };
    like($@, qr!^Space is 4-dimensional \(gnuplot display only work in 2 or 3 dimensions\) at !, "Dimemsion check");
    $tmp = undef;
    $fh  = undef;
}

ok(@Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot,
   "There is a default gnuplot binary name");
seek(DATA,0,1);	# Old perls needs this
open(STDIN, "<&DATA") || die "Could not dup DATA to STDIN: $!";
my $out = `@Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot 2>&1`;
if ($? || $out eq "") {
    diag("Can't start @Graph::Layout::Aesthetic::Monitor::GnuPlot::gnu_plot. Tests skipped");
    exit;
}
$out =~ /\bVersion\s+(\d+\.\d+)\b/i ||
    die "No recognized version string in $out";
my $version = $1;
if ($version < $MIN_VERSION) {
    diag("You have gnuplot version $version, but I need at least $MIN_VERSION. Tests skipped");
    exit;
}
if (my ($dev) = $out =~ /(.*?)\s+aborted/) {
    $dev =~ s/.+://;
    $dev =~ s/^\s*//;
    diag("Output device $dev failed. Tests skipped");
    exit;
}

my $monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new;

$aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinEdgeLength");
$aglo->add_force("NodeRepulsion");

# Plot by hand
$aglo->randomize;
$monitor->plot($aglo);
$monitor->command_flush("pause 1");

# Actually do a real monitored layout
$aglo->gloss(monitor => $monitor, monitor_delay => 0);
$monitor->command_flush("pause 1");
$monitor = undef;
__DATA__
show version
plot "-"
1
e
