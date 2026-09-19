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
my @expect  = ( 0 .. 9 );

my $list    = $test->list_class->new;
$list->push( $_ )  for @expect;

cmp_deeply scalar $list->flat_list, \@expect, 'List pushed as expected';

my $frag = $list->first( sub { $_[0] == 5 } )->$method;

cmp_deeply scalar $list->flat_list, [ 0 .. 4 ] , "0..4 left on list"
or diag "Botched list after fragment:\n", $list->node;

cmp_deeply scalar $frag->flat_list, [ 5 .. 9 ] , "5..9 onto frag"
or diag "Botched fragment:\n", $frag->node;

done_testing
__END__
