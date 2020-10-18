use strict;
use warnings;
use Test::More;
use Test::Snapshot;

use GraphViz2;
use GraphViz2::Data::Grapher;
use File::Slurp; # For read_file().
use File::Spec;
use XML::Bare;

{
package FakeObj;
sub new { bless {} }
}

my $sub = sub {};
my $data = {
  A => {
    a => {},
    bbbbbb => $sub,
    c123 => $sub,
    d => \$sub,
  },
  C => {
    b => {
      a => {
        a => {},
        b => sub {},
        c => 42,
      },
    },
  },
  els => [qw(element_1 element_2 element_3)],
  glob_ref => \*main::,
  obj => FakeObj->new,
  scalar_ref => \'hello',
};
my $g_dg = GraphViz2::Data::Grapher->new;
my $g = $g_dg->create(name => 's', thing => $data)->graph;
is_deeply_snapshot $g->node_hash, 'nodes data';
is_deeply_snapshot $g->edge_hash, 'edges data';

my $xml = read_file(File::Spec->catfile('t', 'sample.html'), {chomp => 1});
$g_dg = GraphViz2::Data::Grapher->new;
my $bare = XML::Bare->new(text => $xml)->simple;
my ($key) = sort keys %$bare;
$g = $g_dg->create(name => $key, thing => $$bare{$key})->graph;
is_deeply_snapshot $g->node_hash, 'nodes html';
is_deeply_snapshot $g->edge_hash, 'edges html';

$xml = read_file(File::Spec->catfile('t', 'sample.xml'), {chomp => 1});
$g_dg = GraphViz2::Data::Grapher->new;
$bare = XML::Bare->new(text => $xml)->simple;
($key) = sort keys %$bare;
$g = $g_dg->create(name => $key, thing => $$bare{$key})->graph;
is_deeply_snapshot $g->node_hash, 'nodes xml';
is_deeply_snapshot $g->edge_hash, 'edges xml';

done_testing;
