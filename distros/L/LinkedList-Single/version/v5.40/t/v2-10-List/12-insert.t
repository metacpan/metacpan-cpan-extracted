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

my $madness = $test->madness;
my $class   = $test->class;
my $method  = $test->method;
my @expect  = $test->gen_expect;

try
{
    my $list    = $class->new;

    $list->$method( @expect );

    note "List contents:\n", explain $list->node;

    ok $list, 'Populated list is true';
}
catch( $err )
{
    fail "$class -> $method: $err";
}

done_testing
__END__
