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
    my $list    = $class->new;

    $list->unshift( $_ ) for @data;

    my $expect  = @data;
    my $found   = $list->count;

    ok $found == $expect, "Found $expect nodes"
    or diag "Failed count of:\n", explain $list->node;
}
catch( $err )
{
    fail "$class -> $method: $err";
}

done_testing
__END__
