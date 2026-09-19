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
    my $list = $madness->$method;
    isa_ok $list, $class;

    my ( $expect )  = $class =~ m{ (\w+) $}x;
    my $found       = $list->object_type;
    is $found, $expect, "$class is '$found' ($expect)";

    is_deeply [], $list->node, 'List is empty';

    ok( (! $list), 'New empty list is (false)' );
}
catch( $err )
{
    fail "$madness: $err";
}

done_testing
__END__
