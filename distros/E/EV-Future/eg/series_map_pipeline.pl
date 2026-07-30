use strict;
use warnings;
use EV;
use EV::Future;
use feature 'say';

# series_map: the worker runs for the next item only once the previous one has
# called done, so the steps stay in order. Passing a TRUE value to done cancels
# the remaining steps and goes straight to final_cb, which makes it a natural
# fit for a pipeline that should stop at the first failure.
#
# Self-contained: EV timers stand in for real async work.

my @steps = (
    { name => 'connect',  ok => 1 },
    { name => 'migrate',  ok => 1 },
    { name => 'verify',   ok => 0 },   # fails; connect/migrate ran, announce will not
    { name => 'announce', ok => 1 },
);

my (@watchers, @ran, $failed);

say "Running a ", scalar @steps, "-step pipeline...";

series_map(\@steps, sub {
    my ($step, $done) = @_;
    say "  $step->{name} ...";

    # Always wrap done in a closure. EV invokes watcher callbacks as
    # $cb->($watcher, $revents), and the watcher is truthy, so
    #
    #     push @watchers, EV::timer 0.05, 0, $done;
    #
    # would reach done as done->($watcher) and silently cancel the rest of the
    # pipeline, while final_cb still fired as though everything had run.
    push @watchers, EV::timer 0.05, 0, sub {
        push @ran, $step->{name};
        if ($step->{ok}) {
            say "    ok";
            $done->();
        } else {
            $failed = $step->{name};
            say "    failed";
            $done->(1);        # true: skip every remaining step
        }
    };
}, sub {
    say $failed ? "Stopped at '$failed'." : "All steps completed.";
    say "Ran: @ran";
    EV::break;
});

EV::run;
