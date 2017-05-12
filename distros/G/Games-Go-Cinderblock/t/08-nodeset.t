use strict;
use Test::More;

use Games::Go::Cinderblock::Rulemap;
#use Games::Go::Cinderblock::Rulemap::Rect;
# use Test::Exception;
#
# First do delta from a single simple move
{
   my $tor_rm = Games::Go::Cinderblock::Rulemap::Rect->new(
      w=>4,      h=>5,
      wrap_v => 1, wrap_h => 1,
   );
   my @nodes = $tor_rm->all_nodes;
   my $nodeset_1 = $tor_rm->nodeset(@nodes[-5..-2]);
   my $nodeset_1_same = $tor_rm->nodeset(reverse(@nodes[-5..-2]));
   my $nodeset_2 = $tor_rm->nodeset(@nodes[-4..-1]);
   cmp_ok ($nodeset_1, '==', $nodeset_1_same, 'nodeset init order mattersn\'t');
   cmp_ok ($nodeset_1_same, '==', $nodeset_1, 'nodeset init order mattersn\'t');

   cmp_ok ($nodeset_1_same, '!=', $nodeset_2, 'nodeset init with different nodes !=');
   cmp_ok ($nodeset_2, '!=', $nodeset_1, 'nodeset init with different nodes !=');
   ok(!$nodeset_1->has_node($nodes[4]), 'no has before add');
   is($nodeset_1->count, 4,'size before add');
   $nodeset_1->add($nodes[4]);
   ok( $nodeset_1->has_node($nodes[4]), 'has after add');
   is($nodeset_1->count, 5,'size before removal');
   $nodeset_1->remove($nodes[4]);
   is($nodeset_1->count, 4,'size after removal');
   ok(!$nodeset_1->has_node($nodes[4]), 'no has after removal');

   my $entire_board_ns = $tor_rm->all_nodes_nodeset;
   is( $entire_board_ns->count, 20, 'all_nodes nodeset has correct count on 4x5');
}
{
   my $rm = Games::Go::Cinderblock::Rulemap::Rect->new( h=>11,w=>18 );
   my $nw_corner = $rm->nodeset([0,0]);
   my $a1 = $rm->nodeset([1,0],[0,1]);
   my $a2 = $rm->nodeset([0,0], [0,2],[2,0],[1,1]);
   cmp_ok( $nw_corner->adjacent, '==', $a1, 'ns adjacent method');
   cmp_ok( $nw_corner->adjacent->adjacent, '==', $a2, 'ns adjacent method x2');
}
done_testing;
