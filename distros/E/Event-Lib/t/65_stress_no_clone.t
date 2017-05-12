# 0.99_22 removed cloning so let's see how it behaves under stress.
#
# We build a very long event-chain, looking thusly, only much longer:
# timer_new(\&handler, timer_new(\&hander, timer_new(\&handler)))->add;
# With pre-0.99_21 releases, this would have meant a lot of cloning.
#
# The outer timer is added and will on triggering add the event it
# has as additional argument.

use Event::Lib;
use Test;

BEGIN { plan tests => 100; }

use constant TIMEOUT => 0.025;

sub handler {
    my ($ev, $evtype, $arg) = @_;
    ok(1);
    $arg->add(TIMEOUT) if defined $arg;
}

my $code;

for (1 .. 100) {
    $code .= 'timer_new(\&handler, ';
}
for (1 .. 100) {
    $code .= ')';
}
$code .= '->add(TIMEOUT)';

eval $code;

event_mainloop;
