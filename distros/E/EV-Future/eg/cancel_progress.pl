use strict;
use warnings;
use EV;
use EV::Future;
use feature 'say';

# Called in non-void context every primitive returns an EV::Future::Handle,
# which reports progress and can stop further dispatch. In void context no
# handle is allocated, so this costs nothing unless you ask for it.
#
# The shape below is the common one: fan out to several sources, stop as soon
# as enough of them have answered.
#
# Self-contained: EV timers stand in for real async work.

my $WANTED = 3;
my @sources = 1 .. 8;

my (@watchers, @answers);
my $handle;

say "Querying ", scalar @sources, " sources, stopping after $WANTED answers...";

$handle = parallel_map_limit(\@sources, sub {
    my ($n, $done) = @_;

    push @watchers, EV::timer 0.03 * $n, 0, sub {
        push @answers, $n;
        say sprintf "  source %d answered (%d in flight, %d pending)",
            $n, $handle->active, $handle->pending;

        if (@answers == $WANTED) {
            # cancel stops further dispatch; a task already in flight still
            # runs to completion, and the done it eventually calls is ignored.
            # Use cancel(1) instead if you want final_cb to fire anyway.
            $handle->cancel;
            say "  got $WANTED answers, cancelled the rest";
            say sprintf "  after cancel: %d in flight, %d pending",
                $handle->active, $handle->pending;
            EV::break;
            return;
        }

        $done->();
    };
}, 2, sub {
    # Only reached if fewer than $WANTED sources exist, since we cancel above.
    say "Every source answered.";
    EV::break;
});

EV::run;

say "Answers: @answers";
