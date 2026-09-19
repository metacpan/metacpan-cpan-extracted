########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use Scalar::Util    qw( blessed );

use LinkedList::Single::TestUtil;

########################################################################
# tests
########################################################################

my $method  = $test->method;
my $class   = $test->list_class;
my @expect  = $test->gen_expect;
my $n       = int @expect / 2;
my $m       = @expect - $n;

my $list    = $class->new->push_list( @expect );
my $list2   = $list->cursor->next( $n )->$method;
my $list1   = $list->$method;

# at this point $list should be empty with the first
# $n items on $list1 and the top half on $list2;

ok ! $list, '$list is empty'
or diag "Botched list:\n", explain $list;

ok $n == $list1->count, "List 1 has $n items"
or diag "Botched list1:\n", explain $list1;

ok $m == $list2->count, "List 2 has $m items"
or diag "Botched list2:\n", explain $list2;

cmp_deeply [ $list1->flat_list ], [ @expect[0 .. $n - 1     ] ], "Expect [ 0 .. $n )";
cmp_deeply [ $list2->flat_list ], [ @expect[$n.. $#expect   ] ], "Expect [ $n .. $#expect )";

done_testing
__END__
