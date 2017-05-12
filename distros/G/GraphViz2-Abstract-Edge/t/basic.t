
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 11/29/13 23:30:59 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: A basic test for abstract edge hash conversion

use GraphViz2::Abstract::Edge;

my $edge = GraphViz2::Abstract::Edge->new();

is( keys %{ $edge->as_hash }, 0, 'Exported hash has no keys when not modified' );
isnt( keys %{ $edge->as_canon_hash }, 0, 'Exported canon hash has many keys when not modified' );

$edge->color('green');

is( keys %{ $edge->as_hash }, 1, 'Exported hash has 1 key after modification' );
isnt( keys %{ $edge->as_canon_hash }, 0, 'Exported canon hash has many keys when after modification' );

$edge->color('black');

is( keys %{ $edge->as_hash }, 0, 'Exported hash has no keys after setting to default' );
isnt( keys %{ $edge->as_canon_hash }, 0, 'Exported canon hash has many keys when after setting to default' );

done_testing;

