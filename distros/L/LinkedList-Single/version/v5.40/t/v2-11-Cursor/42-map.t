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
my @data    = $test->gen_expect( 8 );
my $n       = 1 + int( @data / 2 );

note "Data:\n", explain \@data;

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
    state $j    = $n;

    --$j    
    or die "\n";

    ++$i % 2 
    ? "value = @_ ($i:$j)"
    : ()
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
    my $j   = $n;

    map
    {
        --$j > 0 && ++$i % 2 
        ? "value = $_ ($i:$j)"
        : ()
    }
    @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
