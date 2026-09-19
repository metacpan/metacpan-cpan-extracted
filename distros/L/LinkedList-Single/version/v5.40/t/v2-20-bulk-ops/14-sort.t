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
my @expect  = $test->gen_expect( 10 );

my $list    = '';

my $prep
= sub( $list_c )
{

    my $lazy
    = sub
    {
        state $data = [ @expect ];

        shift $data->@*  
        // die "\n"
    };

    $list       = $list_c->new->generate_lazy( $lazy );
    my $curs    = $list->next( @expect/2 );

    note "Expect:\n", explain \@expect;
    note "List:\n",   explain $list->node;
    note "Curs:\n",   explain $curs->node;

    $curs
};

my $pass1
= sub( $curs )
{
    $curs->sort;
    $list->flat_list;
};

my $pass2
= sub( $curs )
{
    my $n   = $#expect / 2;

    (
        @expect     [ 0     .. $n       ]
      , sort @expect[ 1+$n  .. $#expect ]
    )
};

$test->generic_cursor( $prep, $pass1, $pass2 );

done_testing
__END__
