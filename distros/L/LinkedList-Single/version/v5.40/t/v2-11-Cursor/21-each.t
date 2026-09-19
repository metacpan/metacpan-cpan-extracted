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
my @data    = $test->gen_expect( 4 );

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->push( $_ ) for @data;

    $list->head 
};

my $pass1
= sub( $curs )
{
    my @result  = ();
    my $i       = 3;

    my $tmp 
    = $curs->$method
    (
        sub( $curs )
        {
            # returns 0 after 3 iterations.
            # leaves three values on 

            push @result, $curs->data;
            --$i
        }
    );

    0 + $tmp->node, @result
};

my $pass2
= sub( $curs )
{
    # $curs is at 0, advance 2 more.

    $curs->advance->advance;

    0 + $curs->node, @data[0..2]
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
