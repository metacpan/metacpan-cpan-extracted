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
my @expect  = reverse sort $test->gen_expect( 10 );

my $prep
= sub( $list_c )
{

    my $lazy
    = sub
    {
        state $data = [ @expect ];

        shift $data->@* // die "\n"
    };

    my $list    = $list_c->new->generate_lazy( $lazy );

    note "Expect:\n", explain \@expect;
    note "List:\n",   explain $list->node;

    $list->cursor
};

my $pass1
= sub( $curs )
{
    $curs->sort->flat_list
};

my $pass2
= sub( $curs )
{
    sort @expect
};

$test->generic_cursor( $prep, $pass1, $pass2 );

done_testing
__END__
