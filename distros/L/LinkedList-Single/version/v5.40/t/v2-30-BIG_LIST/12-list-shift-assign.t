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

my $lazy
= sub
{
    state $i    = 1 + $count;

    --$i or die "\n";
};

my $prep
= sub
{
    $list   = $test->list_class->new->append_lazy( $lazy );

    $count
};

my $base
= sub
{
    state $i    = $count;
    my $j   = --$i for 1 .. $count;
};

my $bench
= sub
{
    my $i   = $list->shift;
};

$test->generic_benchmark
(
    $prep
  , $base
  , $bench
);

__END__
