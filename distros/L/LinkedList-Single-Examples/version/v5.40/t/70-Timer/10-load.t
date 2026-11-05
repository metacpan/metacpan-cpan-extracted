########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;

########################################################################
# tests
########################################################################

use_ok $_
for qw
(
    LinkedList::Single::Example::Timer
    LinkedList::Single::Example::Timer::Array
    LinkedList::Single::Example::Probe
    LinkedList::Single::Example::Bench
    LinkedList::Single::Example::Latency
);

done_testing
__END__
