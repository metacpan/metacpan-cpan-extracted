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
my @data    = $test->gen_expect;

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
    $curs->$method;
    $curs->data
};

my $pass2
= sub( $curs )
{
    $data[ -2 ]
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
