########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

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
    ok ! $list, 'Empty list is False';

    $list->insert( @expect );
    ok $list, 'Populated list is true';

    note "List contents:\n", explain $list->node;

    my @found   = $list->shift;
    ok ! $list, 'Empty list is False'
    or diag "Non-empty list after shift:\n", explain $list->node;

    cmp_deeply \@found, \@expect, 'List data returned';

}
catch( $err )
{
    fail "$class -> $method: $err";
}

done_testing
__END__
