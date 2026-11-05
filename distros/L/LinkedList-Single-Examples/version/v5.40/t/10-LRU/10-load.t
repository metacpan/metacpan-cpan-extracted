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
    LinkedList::Single::Example::LRU
    LinkedList::Single::Example::LRU::Array
    LinkedList::Single::Example::LRU::Order
    LinkedList::Single::Example::LRU::Lazy
    LinkedList::Single::Example::Probe
    LinkedList::Single::Example::Bench
);

done_testing
__END__
