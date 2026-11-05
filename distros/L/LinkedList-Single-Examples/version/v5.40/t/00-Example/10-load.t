########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;

########################################################################
# tests: the libraries shared by all of the examples.
########################################################################

use_ok $_
for qw
(
    LinkedList::Single::Example::Bench
    LinkedList::Single::Example::Latency
    LinkedList::Single::Example::Probe
);

done_testing
__END__
