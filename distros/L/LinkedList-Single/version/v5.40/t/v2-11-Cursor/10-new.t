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

my $class   = $test->class;
my $method  = $test->method;
my @expect  = $test->gen_expect;

my $list    = $test->list_class->new;
$list->insert( @expect );

my $curs    = $class->$method( whence => $list );
ok $curs, 'Cursor on populated list is true.';

my ( $expect )  = $class =~ m{ (\w+) $}x;
my $found       = $curs->object_type;
is $found, $expect, "$class is '$found' ($expect)";

cmp_deeply $list->node, $curs->node, 'List node matches cursor node'
or diag
"Mismatched cursor node\n", explain $list->node, explain $curs->node;

done_testing
__END__
