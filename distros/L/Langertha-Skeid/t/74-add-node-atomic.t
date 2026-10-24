use strict;
use warnings;
use Test::More;
use Langertha::Skeid;

# A re-add that croaks must leave the node it would have replaced where it was (skeid k98):
# every check in add_node runs before remove_node.

sub _routable {
  my ($skeid, $id) = @_;
  my $node = $skeid->pick_node(model => 'm1');
  return $node && ($node->{id} // '') eq $id;
}

my %bad = (
  'unknown engine'        => { engine => 'NoSuchEngine' },
  'unknown rerank_format' => { rerank_format => 'nope' },
  'registry capacity'     => { capacity => { probe => 'registry' } },
);

for my $case (sort keys %bad) {
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://good/v1', model => 'm1', tags => ['local']);
  ok(_routable($skeid, 'n1'), $case.': node routable before the bad re-add');

  ok(!eval { $skeid->add_node(id => 'n1', url => 'http://bad/v1', model => 'm1', %{$bad{$case}}); 1 },
    $case.': the re-add croaks');
  my $nodes = $skeid->list_nodes;
  is(scalar(@$nodes), 1, $case.': the old node is still in the inventory');
  is($nodes->[0]{url}, 'http://good/v1', $case.': and it is the old one');
  ok(_routable($skeid, 'n1'), $case.': and it is still routable');
}

done_testing;
