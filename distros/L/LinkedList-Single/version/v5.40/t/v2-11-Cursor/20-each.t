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
my $sent    = '';

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->unshift( $_ ) for @data;
    $sent       = $list->sentinel->node;

    $list->head 
};

my $pass1
= sub( $curs )
{
    my @result  = ();

    my $tmp 
    = $curs->$method
    (
        sub( $curs )
        {
            push @result, $curs->data;
        }
    );

    0 + $tmp->node, @result
};

my $pass2
= sub( $curs )
{
    0 + $sent, reverse @data
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
