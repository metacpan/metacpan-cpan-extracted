
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 11/29/13 23:30:59 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: A basic test for abstract node hash conversion

use GraphViz2::Abstract::Node;

my $node = GraphViz2::Abstract::Node->new();

is( keys %{ $node->as_hash }, 0, 'Exported hash has no keys when not modified' );
isnt( keys %{ $node->as_canon_hash }, 0, 'Exported canon hash has many keys when not modified' );

$node->color('green');

is( keys %{ $node->as_hash }, 1, 'Exported hash has 1 key after modification' );
isnt( keys %{ $node->as_canon_hash }, 0, 'Exported canon hash has many keys when after modification' );

$node->color('black');

is( keys %{ $node->as_hash }, 0, 'Exported hash has no keys after setting to default' );
isnt( keys %{ $node->as_canon_hash }, 0, 'Exported canon hash has many keys when after setting to default' );

done_testing;

