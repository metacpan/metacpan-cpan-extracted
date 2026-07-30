use strict;
use warnings;
use EV;
use EV::Future;
use Benchmark qw(timethese);

# parallel versus parallel_map, measured two ways, because one way alone is
# misleading in either direction.
#
#   reused    the task closures, or the worker, are built ONCE outside the
#             timed loop. This isolates dispatch overhead, and flatters the
#             task form.
#   per call  rebuilt on every call. This is what the closure-per-item idiom
#             actually forces, because each closure has to capture its own
#             element, and it flatters the map form.
#
# The second is the usual case; the first is what you get if you can hoist a
# fixed task list and reuse it.
#
# Wall-clock on a loaded machine swings more than the effect being measured.
# For the authoritative numbers use instruction counts, which are deterministic:
#
#   valgrind --tool=cachegrind --cache-sim=no --branch-sim=no \
#     --cachegrind-out-file=/dev/null \
#     "$(perl -MConfig -e 'print $Config{perlpath}')" \
#     -Mblib -Iblib/arch -Iblib/lib bench/map_vs_task.pl 100 1
#
# subtracting a zero-iteration run to remove interpreter startup.
#
# Usage: perl -Mblib bench/map_vs_task.pl [ELEMENTS] [SECONDS_PER_CASE]

my $N    = shift(@ARGV) || 100;
my $SECS = shift(@ARGV) || -2;

my @items  = (1 .. $N);
my @tasks  = map { my $i = $_; sub { my $d = shift; $d->() } } @items;
my $worker = sub { my ($i, $d) = @_; $d->() };
my $noop   = sub { };

print "$N elements, per-second rates (higher is better)\n";

for my $unsafe (0, 1) {
    my $mode = $unsafe ? 'unsafe' : 'safe';

    my $r = timethese($SECS, {
        'parallel     reused  ' => sub { parallel(\@tasks, $noop, $unsafe) },
        'parallel_map reused  ' => sub { parallel_map(\@items, $worker, $noop, $unsafe) },
        'parallel     per call' => sub {
            parallel([ map { my $i = $_; sub { my $d = shift; $d->() } } @items ],
                     $noop, $unsafe);
        },
        'parallel_map per call' => sub {
            parallel_map(\@items, sub { my ($i, $d) = @_; $d->() }, $noop, $unsafe);
        },
    }, 'none');

    my %rate;
    for my $k (keys %$r) {
        my $cpu = $r->{$k}[1] + $r->{$k}[2];
        $rate{$k} = $cpu > 0 ? $r->{$k}[5] / $cpu : 0;
    }

    print "\n  --- $mode mode ---\n";
    printf "  %-22s %10.0f/s\n", $_, $rate{$_} for sort keys %rate;

    for my $how ('reused  ', 'per call') {
        my ($t, $m) = @rate{ "parallel     $how", "parallel_map $how" };
        printf "  map form is %+.0f%% on '%s'\n", 100 * ($m - $t) / $t, $how
            if $t;
    }
}
