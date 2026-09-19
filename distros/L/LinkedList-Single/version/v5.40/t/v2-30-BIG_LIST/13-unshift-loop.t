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

my $list    = $test->list_class->new;
my $count   = 1;
my $nodes
= $^P
? 2 ** 10
: $ENV{ LIST_SIZE } || 2 ** 24
;

my $prep
= sub
{
    $count
};

my $bench
= sub
{
    my $i   = -1;

    $list->unshift( ++$i ) for 1 .. $nodes;
    return
};

my $post
= sub
{
    my $found   = $list->count;

    ok $found == $nodes, "Node count: $found ($nodes)";
};

$test->generic_benchmark
(
    $prep
  , undef
  , $bench
  , $post
);

__END__
