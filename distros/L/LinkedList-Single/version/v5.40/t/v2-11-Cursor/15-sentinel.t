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
my @data    = $test->gen_expect;

try
{
    # can't test this on a populated list until we've
    # validted advance on the cursor.

    my $list    = $test->list_class->new;
    $list->unshift( $_ ) for $test->gen_expect;

    my $curs    = $list->cursor;
    $curs->advance while $curs->node->@*;

    my $expect  = $curs->node;
    my $found   = $list->$method->node;

    ok $expect == $found, "Found sentinel at $found ($expect)"
    or diag "Mismatched sentinel:\n", explain $list->node;
}
catch( $err )
{
    fail "$class -> $method: $err";
}

done_testing
__END__
