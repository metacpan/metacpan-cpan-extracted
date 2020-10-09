use strict;
use warnings;
use Test::More;
use Test::Snapshot;

use GraphViz2;
use File::Spec;
use GraphViz2::Parse::RecDescent;
use Parse::RecDescent;

sub read_file {
  open my $fh, '<:encoding(UTF-8)', $_[0] or die "$_[0]: $!";
  local $/;
  <$fh>;
}

my $g_rd = GraphViz2::Parse::RecDescent->new;
my $grammar = read_file(File::Spec->catfile('t', 'sample.recdescent.1.dat') );
my $parser = Parse::RecDescent->new($grammar);
$g_rd->create(name => 'Grammar', grammar => $parser);
my $g = $g_rd->graph;
is_deeply_snapshot $g->node_hash, 'nodes recdescent';
is_deeply_snapshot $g->edge_hash, 'edges recdescent';

done_testing;
