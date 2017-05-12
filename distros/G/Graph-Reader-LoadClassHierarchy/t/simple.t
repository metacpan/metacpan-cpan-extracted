#!perl -T

use strict;
use warnings;
use Test::More tests => 11;
use Graph::Reader::LoadClassHierarchy;


package Foo;

use strict;
use warnings;

package Bar;

use strict;
use warnings;
use base 'Foo';

package FooBar;

use strict;
use warnings;
use base qw( Foo Bar );


package main;

my $reader = Graph::Reader::LoadClassHierarchy->new;
isa_ok( $reader, 'Graph::Reader::LoadClassHierarchy');

my $graph = $reader->read_graph('FooBar');
isa_ok( $graph, 'Graph' );


for my $class (qw( Foo Bar FooBar )) {
    ok( $graph->has_vertex( $class ), "node $class exists" );
}

ok( $graph->has_edge( 'Bar'    => 'Foo' ), 'Bar inherits from Foo'    );
ok( $graph->has_edge( 'FooBar' => 'Foo' ), 'FooBar inherits from Foo' );
ok( $graph->has_edge( 'FooBar' => 'Bar' ), 'FooBar inherits from Bar' );

ok( !$graph->has_edge( 'Foo' => 'Bar'    ), 'Foo doesn\'t inherit from Bar'    );
ok( !$graph->has_edge( 'Foo' => 'FooBar' ), 'Foo doesn\'t inherit from FooBar' );
ok( !$graph->has_edge( 'Bar' => 'FooBar' ), 'Bar doesn\'t inherit from FooBar' );
