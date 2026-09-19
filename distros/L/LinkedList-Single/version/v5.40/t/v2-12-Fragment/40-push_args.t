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

my $method  = $test->method;
my @expect  = $test->gen_expect;

my $pass1
= sub( $list )
{
    $list->$method( @expect )->flat_list
};

my $pass2
= sub( $list )
{
    @expect
};

$test->generic_list( $pass1, $pass2 );

done_testing
__END__
