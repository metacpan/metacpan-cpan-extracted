########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use LinkedList::Single::TestUtil;

########################################################################
# tests
########################################################################


my $class   = $test->class;
my $method  = $test->method;

try
{
    my @empty   = $class->new->$method;
    ok ! @empty, "$method on new list is empty";
}
catch( $err )
{
    fail "$method on empty list: $err";
}

done_testing
__END__
