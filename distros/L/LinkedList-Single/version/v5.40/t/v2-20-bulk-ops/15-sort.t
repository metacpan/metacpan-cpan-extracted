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
my @data    = $test->gen_expect( 10 );
my $n       = @data / 2;
my @expect  = 
(
    @data       [ 0     .. $n - 1   ] 
  , sort @data  [ $n    .. $#data   ]
);


my $prep
= sub( $list_c )
{
    my $lazy
    = sub
    {
        state $data = [ @data ];

        shift $data->@*  
        // die "\n"
    };

    my $list    = $list_c->new->push_args( @data );
    my $curs    = $list->cursor;

    $curs
};

my $pass1
= sub( $curs )
{
    $curs->next( @data/2 )->sort;
    $curs->flat_list
};

my $pass2 = sub( $curs )
{
    note "Sorted data:\n",  explain $curs->node;
    note "Expected:\n",     explain \@expect;
    @expect
};

$test->generic_cursor( $prep, $pass1, $pass2 );

done_testing
__END__
