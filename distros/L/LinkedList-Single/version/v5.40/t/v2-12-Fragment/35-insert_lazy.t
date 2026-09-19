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
my @prior   = ( 'a' .. 'f' );
my @after   = (  0  ..  9  );

sub lazy
{
    my $l   = [ @_ ];

    sub
    {
        shift $l->@*
        // die "\n"
    }
}

my $list    = $test->list_class->new->insert_lazy( lazy @prior  );

$list->head->$method( lazy @after );

my $found   = $list->flat_list;
my $expect  = [ @after, @prior ];

cmp_deeply $found, $expect, 'found : expected'
or diag "Found:\n"  , explain $list->node;

done_testing;
