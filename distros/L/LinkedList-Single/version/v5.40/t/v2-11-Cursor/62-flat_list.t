########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use LinkedList::Single::TestUtil;

use Sub::Name       qw( subname );

########################################################################
# tests
########################################################################

my $method  = $test->method;
my @expect  = $test->gen_expect( 10 );

my $lazy
= sub
{
    state $list = [ @expect ];

    shift $list->@*
    // die "\n"
};

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new->push_lazy( $lazy );

    $list->cursor
};

my $pass1
= sub( $curs )
{
    $curs->$method
};

my $pass2
= sub
{
    @expect
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
