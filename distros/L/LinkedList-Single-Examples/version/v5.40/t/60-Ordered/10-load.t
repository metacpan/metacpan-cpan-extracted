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
    LinkedList::Single::Example::Ordered
    LinkedList::Single::Example::Ordered::Buckets
    LinkedList::Single::Example::Ordered::Sorted
    LinkedList::Single::Example::Ordered::Hash
    LinkedList::Single::Example::Probe
    LinkedList::Single::Example::Bench
    LinkedList::Single::Example::Latency
);

done_testing
__END__
