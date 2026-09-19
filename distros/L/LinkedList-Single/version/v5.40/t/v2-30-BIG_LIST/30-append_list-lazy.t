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

my $count   = 8;
my $nodes
= $^P
? 8
: $ENV{ LIST_SIZE } || 2 ** 24
;

my $list    = '';
my $i       = 0;
my $lazy    = sub { --$i or die "\n" };

my $prep
= sub
{
    say "$count iterations appending lazy list of $nodes nodes";

    $count
};

my $base
= sub
{
    sub
    {
        state $i = 1 + $nodes;
        --$i or die "\n"
    }
};

my $bench
= sub
{
    $test->list_class->new->append_lazy( $base->() );
};

$test->generic_benchmark
(
    $prep
  , $base
  , $bench
  , undef
);

__END__
