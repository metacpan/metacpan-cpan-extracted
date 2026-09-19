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

my $method  = $test->method;
my @data    = $test->gen_expect;

my $list    = $test->list_class->new;
$list->unshift( @data );

for my $curs (  $list->head->cursor )
{
    cmp_deeply
        $list->node
      , $curs->node
      , 'List node matches cursor node'
    or diag
        "Mismatched cursor node\n"
      , explain $list->node
      , explain $curs->node
    ;
}

done_testing
__END__
