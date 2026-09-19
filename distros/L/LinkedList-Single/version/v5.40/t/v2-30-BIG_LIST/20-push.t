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
? 32
: $ENV{ LIST_SIZE } || 2 ** 24
;

my $list    = $test->list_class->new;
my $curs    = $list->cursor;

my $prep
= sub
{
    $count
};

my $bench
= sub
{
    state $i    = 0;

    $curs->push( ++$i )->advance;
};

my $post
= sub
{
    my $found   = $list->count;
    ok $found == $count, "Node count: $found ($count)";
};

$test->generic_benchmark
(
    $prep
  , undef
  , $bench
  , $post
);

__END__
