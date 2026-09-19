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

my $list    = '';

my $prep
= sub( $list_c )
{
    $list   = $list_c->new;
    $list->unshift( $_ ) for @data;

    $list->head 
};

my $pass1
= sub( $curs )
{
    $curs->count
};

my $pass2
= sub( $curs )
{
    scalar @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
