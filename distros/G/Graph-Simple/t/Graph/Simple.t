# Simple.t

use strict;
use warnings;
use Test::More;

use Graph::Simple;

sub undirected_weighted_graph {

    my $g = Graph::Simple->new( is_directed => 0, is_weighted => 1 );

    $g->add_edge( 'Joe', 'Bob',  3 );
    $g->add_edge( 'Joe', 'Mike', 1 );

    $g->add_edge( 'Bob', 'Mike', 2 );
    $g->add_edge( 'Bob', 'Sam',  8 );

    $g->add_edge( 'Sam', 'Kelly', 6 );

    $g->add_edge( 'Kelly', 'Vic',  3 );
    $g->add_edge( 'Kelly', 'Finn', 2 );

    $g->add_edge( 'Finn', 'Vic',  3 );
    $g->add_edge( 'Finn', 'Jess', 2 );

    $g->add_edge( 'Jess', 'Vic', 2 );

    $g->add_edge( 'Vic', 'Mike', 4 );

    return $g;
}

sub directed_weighted_graph {
    my $g = Graph::Simple->new( is_directed => 1, is_weighted => 1 );

    $g->add_edge( 'Al',  'Bob', 2 );
    $g->add_edge( 'Al',  'Jim', 3 );
    $g->add_edge( 'Bob', 'Al',  4 );
    $g->add_edge( 'Ed',  'Bob', 1 );
    $g->add_edge( 'Jim', 'Ed',  5 );

    return $g;
}

subtest 'Delete edges on a directed graph' => sub {
    my $g = Graph::Simple->new( is_directed => 1 );

    $g->add_edge( 'Al',  'Bob', 2 );
    $g->add_edge( 'Bob', 'Al',  2 );
    $g->add_edge( 'Bob', 'Ed',  1 );

    is_deeply [ $g->neighbors('Al') ], ['Bob'], "Bob is a neighbor of Al";
    is_deeply [ $g->neighbors('Bob') ], [ 'Al', 'Ed' ],
      "Al and Ed are neighbors of Bob";

    $g->delete_edge( 'Al', 'Bob' );
    is_deeply [ $g->neighbors('Al') ], [],
      "Since the edge 'Al to Bob' is deleted, Al has no more neighbors";

    is_deeply [ $g->neighbors('Bob') ], [ 'Al', 'Ed' ],
      "... but Bob still has Al and Ed as neighbors";
};

subtest 'Delete edges on an undirected graph' => sub {
    my $g = Graph::Simple->new( is_directed => 0 );

    $g->add_edge( 'Al',  'Bob', 2 );
    $g->add_edge( 'Bob', 'Ed',  1 );

    is_deeply [ $g->neighbors('Al') ], ['Bob'], "Bob is a neighbor of Al";
    is_deeply [ $g->neighbors('Bob') ], [ 'Al', 'Ed' ],
      "Al and Ed are neighbors of Bob";

    $g->delete_edge( 'Al', 'Bob' );
    is_deeply [ $g->neighbors('Al') ], [],
      "Since the edge 'Al to Bob' is deleted, Al has no more neighbors";

    is_deeply [ $g->neighbors('Bob') ], ['Ed'],
      "... and Bob lost Al from his neighbors";
};


subtest "basic graph features on undirected graph" => sub {
    my $g = undirected_weighted_graph();

    is_deeply
      [ sort $g->neighbors('Vic') ],
      [ sort qw(Kelly Mike Finn Jess) ],
      "Neighbours are correct for Vic";

    foreach my $t (
        [ 'Bob',   'Sam',  8 ],
        [ 'Sam',   'Bob',  8 ],
        [ 'Kelly', 'Vic',  3 ],
        [ 'Vic',   'Finn', 3 ],
      )
    {
        my ( $u, $v, $w ) = @$t;
        is $g->weight( $u, $v ), $w, "Edge $u,$v weights $w";
    }

    $g->weight( 'Bob', 'Sam', 43 );
    is $g->weight( 'Bob', 'Sam' ), 43, "weight has been set";

    eval { $g->neighbors('NonExistentVertex'); };
    like $@, qr{Unknown vertex 'NonExistentVertex'},
      "neighbors triggers an unknown vertex exception";

    ok $g->is_adjacent( 'Bob', 'Mike' ), "Bob is adjacent to Mike";
    ok !$g->is_adjacent( 'Bob', 'Finn' ), "Bob is not adjacent to Finn";
};

subtest "basic graph features on directed graph" => sub {
    my $g = directed_weighted_graph();

    is_deeply
      [ $g->neighbors('Bob') ],
      [qw(Al)],
      "Neighbours are correct for Bob";

    is_deeply
      [ sort $g->neighbors('Al') ],
      [ sort qw(Bob Jim) ],
      "Neighbours are correct for Al";

    foreach my $t (
        [ 'Bob', 'Al',  4 ],
        [ 'Al',  'Bob', 2 ],
        [ 'Al',  'Jim', 3 ],
        [ 'Ed',  'Bob', 1 ],
      )
    {
        my ( $u, $v, $w ) = @$t;
        is $g->weight( $u, $v ), $w, "Edge $u,$v weights $w";
    }
};

subtest 'Breadth-First Search' => sub {
    my $g = undirected_weighted_graph();

    is_deeply $g->breadth_first_search('Vic'),
      { Bob   => "Mike",
        Finn  => "Vic",
        Jess  => "Vic",
        Joe   => "Mike",
        Kelly => "Vic",
        Mike  => "Vic",
        Sam   => "Kelly"
      },
      "BFS parents hash is ok";
};

subtest 'Depth-First Search' => sub {

    # See example in http://en.wikipedia.org/wiki/Depth-first_search
    my $g = Graph::Simple->new( is_directed => 0, is_weighted => 0 );
    $g->add_edge( 'A', 'B' );
    $g->add_edge( 'A', 'C' );
    $g->add_edge( 'A', 'E' );
    $g->add_edge( 'B', 'D' );
    $g->add_edge( 'B', 'F' );
    $g->add_edge( 'C', 'G' );
    $g->add_edge( 'F', 'E' );

    my @preorder;
    my @postorder;
    $g->depth_first_search(
        'A',
        cb_vertex_discovered => sub {
            push @preorder, $_[0];
        },
        cb_vertex_processed => sub {
            push @postorder, $_[0];
        },
    );

    is_deeply \@preorder, [qw(A B D F E C G)],
      "The vertices are visited in correct order";

    is_deeply \@postorder, [qw(D E F B G C A )], "Last order visits are good";

    @preorder  = ();
    @postorder = ();
    $g->depth_first_search('A');
    is_deeply \@preorder, [],
      "the cb_vertex_discovered default callback does nothing";
    is_deeply \@postorder, [],
      "the cb_vertex_processed default callback does nothing";
};

subtest "Prim" => sub {
    my $g = Graph::Simple->new( is_directed => 0, is_weighted => 1 );

    $g->add_edge( 'Don',   'Bob',   2 );
    $g->add_edge( 'Don',   'Ron',   3 );
    $g->add_edge( 'Ron',   'Jim',   1 );
    $g->add_edge( 'Ron',   'Mike',  4 );
    $g->add_edge( 'Mike',  'Alice', 2 );
    $g->add_edge( 'Alice', 'Jim',   3 );
    $g->add_edge( 'Jim',   'Bob',   4 );
    $g->add_edge( 'Bob',   'Alice', 7 );

    my @tour;
    my $spanning_tree = $g->prim('Ron');

    $spanning_tree->depth_first_search(
        'Ron',
        cb_vertex_discovered => sub {
            push @tour, $_[0];
        }
    );

    is_deeply \@tour, [ 'Ron', 'Jim', 'Alice', 'Mike', 'Don', 'Bob' ],
      "prim tour looks fine";
};

subtest 'Dijkstra' => sub {
    my $g = undirected_weighted_graph;

    my $res = $g->dijkstra('Mike');

    is_deeply $res->{distances},
      { Mike  => 0,
        Vic   => 4,
        Joe   => 1,
        Bob   => 2,
        Sam   => 10,
        Kelly => 7,
        Finn  => 7,
        Jess  => 6,
      },
      "distances are good for Mike";

    is_deeply [ $g->shortest_path( 'Mike', 'Kelly' ) ], [ qw(Mike Vic Kelly) ],
      "Shortest path from Mike to Kelly";
};

done_testing;
