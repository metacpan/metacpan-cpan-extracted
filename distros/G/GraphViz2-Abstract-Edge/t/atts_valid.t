
use strict;
use warnings;

use Test::More;

# FILENAME: atts_valid.t
# CREATED: 11/30/13 01:55:43 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Make sure canonicalised attributes pass muster with graphviz

use GraphViz2;
use GraphViz2::Abstract::Edge;
use Path::Tiny;
use Test::Fatal qw(exception);

my $tempdir       = Path::Tiny->tempdir;
my $render_engine = 'ps';

my $file_a = $tempdir->child('a.svg');
my $file_b = $tempdir->child('b.svg');

subtest "Generate test file with canonicalised data" => sub {
  is(
    exception {
      my $graph = GraphViz2->new();
      my $node  = GraphViz2::Abstract::Edge->new();
      my $hash  = $node->as_canon_hash();
      $graph->add_edge( from => a => to => b => %{$hash} );
      $graph->run( format => $render_engine, output_file => "$file_a" );
    },
    undef,
    'GraphViz2 handled canonicalised data OK'
  );
};
subtest "Generate test file with minimal data" => sub {
  is(
    exception {
      my $graph = GraphViz2->new();
      my $node  = GraphViz2::Abstract::Edge->new();
      my $hash  = $node->as_hash();
      $graph->add_edge( from => a => to => b => %{$hash} );
      $graph->run( format => $render_engine, output_file => "$file_b" );
    },
    undef,
    'GraphViz2 handled basically an empty edge OK'
  );
};
subtest "Compare generated $render_engine files line-by-line" => sub {
  my @lines_a = $file_a->lines_raw();
  my @lines_b = $file_b->lines_raw();
  for ( 0 .. $#lines_a ) {
    note $lines_a[$_];
    is( $lines_a[$_], $lines_b[$_], "line $_ of $render_engine is the same regardless of canonicalising" );
  }
};
done_testing;

