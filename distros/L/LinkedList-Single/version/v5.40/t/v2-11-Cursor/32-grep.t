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
my $n       = int @data / 2;

note "Test data:\n", explain \@data;

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->push( $_ ) for @data;

    $list->cursor
};

my $filter
= subname runt_odd_count
=> sub
{
$DB::single = 1;

    state $i    = 0;
    state $j    = $n;

    --$j
    or die "\n";

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
    state $i    = 0;
    state $j    = $n;

    grep { --$j > 0 and ++$i % 2 } @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
