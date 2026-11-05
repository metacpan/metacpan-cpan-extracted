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
    LinkedList::Single::Example::Handoff
    LinkedList::Single::Example::Handoff::Array
    LinkedList::Single::Example::Handoff::Marked
    LinkedList::Single::Example::Lock
    LinkedList::Single::Example::Probe
    LinkedList::Single::Example::Bench
);

done_testing
__END__
