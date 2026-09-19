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

    # yes, this backdoor's the structure. 

    cmp_deeply $list->node, [], 'Found empty arrayref';
    ok ! $list, 'Empty list is false';

    my $expect  = [ [], 'frobnicate' ];
    $list->node = $expect;
    cmp_deeply $list->node, $expect, 'Found nested list struct';
    ok $list, 'Populated list is true';
}
catch( $err )
{
    fail "$class -> $method: $err";
}

done_testing
__END__
