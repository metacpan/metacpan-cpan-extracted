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

my $class   = $test->list_class;

my $count
= $^P
? 32
: $ENV{ LIST_SIZE } || 2 ** 16
;

my $list    = '';
my $i       = 0;

my $prep
= sub
{
    $list   = $class->new->push_args( 1 .. $count );
    $count
};

my $base
= sub
{
    state $i    = $count;
    my $sub     = sub(){ --$i };

    $sub->() for 1 .. $count;
};

my $post
= sub
{
    my $found   = $list->count;

    ok $found == 0, "List size: $found (0)";
};

$test->generic_benchmark
(
    $prep
  , $base
  , sub() { $list->pop }
  , $post
);

__END__
