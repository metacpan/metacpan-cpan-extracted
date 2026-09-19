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

my $count
= $^P
? 2 **  3
: 2 ** 24
;

my $list    = '';

my $prep
= sub
{
    $list   = $test->list_class->new;
    $count
};

my $base
= sub
{
    state $i    = $count;
    my $sub     = sub( $x ){ --$i };

    $sub->( 1 ) for 1 .. $count;
};

my $bench
= sub
{
    state $i    = $count;
    $list->unshift( --$i );
};

my $post
= sub
{
    my $found   = $list->count;

    ok $found == $count, "List size: $found ($count)";
};

$test->generic_benchmark
(
    $prep
  , $base
  , $bench
  , $post
);

__END__
