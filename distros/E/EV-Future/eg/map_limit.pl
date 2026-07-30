use strict;
use warnings;
use EV;
use EV::Future;
use feature 'say';

# parallel_map_limit: one worker per item, at most $LIMIT in flight.
#
# Before the map form existed this needed a closure per item purely to bind
# the item:
#
#     parallel_limit([ map { my $j = $_;
#                            sub { my $done = shift; work($j, $done) } } @jobs ],
#                    3, sub { ... });
#
# The map form hands the item to a single worker instead, so there is one
# closure for the whole list rather than one per element.
#
# Self-contained: EV timers stand in for whatever real async work you have.

my @jobs  = map { { id => $_, cost => 0.02 + ($_ % 3) * 0.02 } } 1 .. 9;
my $LIMIT = 3;

my (@watchers, %finished);
my ($in_flight, $peak) = (0, 0);

say "Running ", scalar @jobs, " jobs, at most $LIMIT at a time...";

parallel_map_limit(\@jobs, sub {
    my ($job, $done) = @_;

    $in_flight++;
    $peak = $in_flight if $in_flight > $peak;

    push @watchers, EV::timer $job->{cost}, 0, sub {
        $finished{ $job->{id} } = $job->{cost};
        $in_flight--;
        $done->();
    };
}, $LIMIT, sub {
    say sprintf "  job %d took %.2fs", $_, $finished{$_}
        for sort { $a <=> $b } keys %finished;
    say "Peak concurrency was $peak, limit was $LIMIT.";
    EV::break;
});

EV::run;
