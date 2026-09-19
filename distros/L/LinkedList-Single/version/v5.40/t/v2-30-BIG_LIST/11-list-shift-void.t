########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use LinkedList::Single::TestUtil;

########################################################################
# tests
########################################################################

my $count
= $^P
? 2 ** 10
: $ENV{ LIST_SIZE } || 2 ** 24
;

my $list    = '';
my $i       = 0;

my $prep
= sub
{
    $list   = $test->list_class->new;;

    $list->unshift( $_ )
    for 1 .. $count;

    $count
};

my $base
= sub
{
    $list->count
};

my $bench
= sub
{
    $list->shift;
    return
};

$test->generic_benchmark
(
    $prep
  , $base
  , $bench
);

__END__
