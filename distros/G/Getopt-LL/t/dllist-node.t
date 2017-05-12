use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib 't';
use lib $Bin;
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 52;

plan( tests => $THIS_TEST_HAS_TESTS );

use Getopt::LL::DLList::Node;

my @nodes = qw(
    top
    left
    middle
    right
    bottom
);

my %address_of;

my $top     = $address_of{'top'}    = Getopt::LL::DLList::Node->new('top');
my $left    = $address_of{'left'}   = Getopt::LL::DLList::Node->new('left');
my $middle  = $address_of{'middle'} = Getopt::LL::DLList::Node->new('middle');
my $right   = $address_of{'right'}  = Getopt::LL::DLList::Node->new('right');
my $bottom  = $address_of{'bottom'} = Getopt::LL::DLList::Node->new('bottom');

for my $node (values %address_of) {
    isa_ok($node, 'Getopt::LL::DLList::Node');
    can_ok($node, 'next');
    can_ok($node, 'prev');
    can_ok($node, 'data');
    can_ok($node, 'free');
}

$top->set_next($left);          # top.next = left
is( $top->next, $left );

$left->set_prev($top);          # left.prev = top
is( $left->prev, $top );
$left->set_next($middle);       # left.next = middle
is( $left->next, $middle);

$middle->set_prev($left);       # middle.prev = left
is( $middle->prev, $left );
$middle->set_next($right);      # middle.next = right
is( $middle->next, $right);
is( $top->next->next, $middle); # top.next.next = middle
is( $middle->prev->prev, $top); # middle.prev.prev = top

$right->set_prev($middle);
is( $right->prev, $middle );
$right->set_next($bottom);
is( $right->next, $bottom );

is( $right->prev->prev, $left);
is( $right->prev->prev->prev, $top);

$bottom->set_prev($right);
is( $bottom->prev, $right );

is( $middle->next->next, $bottom);
is( $left->next->next->next, $bottom);
is( $top->next->next->next->next, $bottom);

ok(!$bottom->next);
ok(!$top->prev);

# ------------------------------------------------ #
# Ascending Traversal 
##diag('Ascending traversal');
my $i = 0;
my $current_node = $top;
ASCENDING:
while ($current_node) {
   last ASCENDING if !$current_node;
    is( $current_node->data, $nodes[$i],
        sprintf('node %d.data[%s] == [%s]', $i, $current_node->data,
            $nodes[$i])
    );

    $i++;
    $current_node = $current_node->next;
}

# ------------------------------------------------ #
# Descending traversal.
#diag('Descending traversal');
$i = $#nodes;
$current_node = $bottom;
DESCENDING:
while ($current_node) {
    is( $current_node->data, $nodes[$i],
        sprintf('node %d.data[%s] == [%s]', $i, $current_node->data,
            $nodes[$i])
     );

     $i--;
     $current_node = $current_node->prev;
}

for my $node (values %address_of) {
    $node->DESTROY( );
}


