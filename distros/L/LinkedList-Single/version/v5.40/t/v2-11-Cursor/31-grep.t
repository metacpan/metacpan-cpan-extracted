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
my @data    = $test->gen_expect( 10 );

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->push( $_ ) for @data;

    $list->head 
};

my $filter
= subname odd_count
=> sub
{
    state $i    = 0;

    ++$i % 2
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

    grep
    {
        ++$i % 2
    }
    @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
