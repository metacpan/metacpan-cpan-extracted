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

try
{
    my $list    = $class->new;

    my $expect  = $list->node;
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
