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
my @data    = $test->gen_expect;

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->push( $_ ) for @data;

    $list->cursor
};

my $filter
= subname runt_odd_count_ref
=> sub
{
    state $i    = 0;

    if( ++$i %2 )
    {
        "value = @_"
    }
    else
    {
        ()
    }
};

my $pass1
= sub( $curs )
{
    $curs->$method( $filter )
};

my $pass2
= sub
{
    my $i   = 0;

    map
    {

        if( ++$i %2 )
        {
            "value = $_"
        }
        else
        {
            ()
        }
    }
    @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
