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
my @data    = ( 0 .. 9 );

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->unshift( $_ ) for @data;

    $list->cursor
};

my $pass1
= sub( $curs )
{
$DB::single = 1;

    $curs->$method
};

my $pass2
= sub
{
    map { [ $_ ] } reverse @data;
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
