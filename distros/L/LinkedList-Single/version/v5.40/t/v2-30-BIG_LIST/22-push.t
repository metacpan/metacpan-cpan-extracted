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
? 32
: $ENV{ LIST_SIZE } || 2 ** 14
;

my $list    = '';
my $i       = 0;

my $prep
= sub
{
    $list   = $test->list_class->new;;
    $count
};

my $bench
= sub
{
    $list->push( ++$i );
};

$test->generic_benchmark
(
    $prep
  , undef
  , $bench
);

__END__
