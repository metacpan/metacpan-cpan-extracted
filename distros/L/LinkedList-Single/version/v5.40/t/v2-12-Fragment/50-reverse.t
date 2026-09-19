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
my @expect  = $test->gen_expect;


my $prep
= sub( $list_c )
{
    $list_c
    ->new
    ->generate_lazy
    (
        sub()
        {
            state $e    = [ @expect ];

            shift $e->@*
            // die "\n";
        }
    )
    ->fragment
};

my $pass1
= sub( $frag )
{
    $frag->$method->flat_list
};

my $pass2
= sub( $frag )
{
    reverse @expect
};

$test->generic_fragment( $prep, $pass1, $pass2 );

done_testing
__END__
