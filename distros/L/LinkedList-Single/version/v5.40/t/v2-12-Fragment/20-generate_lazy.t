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

my $gen
= sub()
{
    state $d    = [ @expect ];

    shift $d->@*
    // die "\n";
};

my $prep
= sub( $list_c )
{
    $list_c->new->$method( $gen )->fragment
};

my $pass1
= sub( $frag )
{
    $frag->flat_list
};

my $pass2
= sub( $frag )
{
    @expect
};

$test->generic_fragment( $prep, $pass1, $pass2 );

done_testing
__END__
