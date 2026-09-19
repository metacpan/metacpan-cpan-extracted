########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::TestUtil;

########################################################################
# tests
########################################################################

my $method  = $test->method;
my @expect  = $test->gen_expect;

my $list    = $test->list_class->new;
$list->push( $_ ) for @expect;

cmp_deeply scalar $list->flat_list, \@expect, 'List pushed as expected'
or diag "Botched list after push:\n", explain $list->node;

my $frag    = $list->fragment;

ok ! $list, 'Source list (whence) is false'
or diag "Non-empty list after fragment:\n", explain $list->node;

cmp_deeply scalar $frag->flat_list, \@expect, 'Fragment contains list'
or diag "Non-matching fragment:\n", explain $frag->node;

done_testing
__END__
