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

use_ok $madness;
can_ok $class, $method;

try
{
    my $list    = $madness->new ;
    my $frag    = $class->$method;

    my ( $expect )  = $class =~ m{ (\w+) $}x;
    my $found       = $frag->object_type;
    is $found, $expect, "$class is '$found' ($expect)";

    ok( (! $frag)           , 'New empty fragment is (false)' );
    ok $frag->is_sentinel   , 'New empty fragment is a sentinel';
}
catch( $err )
{
    fail "$madness: $err";
}

done_testing
__END__
