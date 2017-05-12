
use strict;
use warnings;

use Test::More;

# FILENAME: subclass.t
# CREATED: 11/29/13 23:40:55 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Ensure subclass attribute defaults are exported

{

  package t::GraphNode;
  use parent 'GraphViz2::Abstract::Node';
  use Class::Tiny { color => 'green', };
}

my $node = t::GraphNode->new();
my $hash = $node->as_hash;

ok( exists $hash->{color}, 'color is defined' );
is( $hash->{color}, 'green', 'color is green' );
is( keys %{$hash},  1,       'Only keys required are shown' );

done_testing;

