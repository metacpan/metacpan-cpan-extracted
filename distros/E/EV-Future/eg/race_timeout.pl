use strict;
use warnings;
use EV;
use EV::Future;
use feature 'say';

# race: the first task to call done wins, and its arguments go to final_cb.
# Racing real work against a timer is the usual reason to reach for it.
#
# Losing tasks keep running. EV::Future does not cancel their watchers, because
# it did not create them; hold the watchers in a shared lvalue and clear it from
# final_cb, which is what @watchers is doing here.
#
# Self-contained: EV timers stand in for real async work.

sub attempt {
    my ($work_time, $timeout) = @_;
    my @watchers;

    race([
        sub {
            my $done = shift;
            push @watchers, EV::timer $work_time, 0, sub { $done->(ok => $work_time) };
        },
        sub {
            my $done = shift;
            push @watchers, EV::timer $timeout, 0, sub { $done->(timeout => $timeout) };
        },
    ], sub {
        my ($outcome, $after) = @_;
        say sprintf "  work=%.2fs timeout=%.2fs -> %s after %.2fs",
            $work_time, $timeout, $outcome, $after;
        @watchers = ();      # drop the loser's watcher
        EV::break;
    });

    EV::run;
}

say "Racing work against a timeout...";
attempt(0.05, 0.20);   # work wins
attempt(0.30, 0.10);   # timeout wins
say "Done.";
