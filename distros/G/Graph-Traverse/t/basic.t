# -*- mode: cperl; -*-
use strict;
use Test::More;

use Graph;
use Graph::Traverse;

my $g = new_ok( 'Graph' );
ok ($g->add_path(qw(A B C D)), 'Add path');

{
    my @paths = $g->traverse([qw(A)],);
    is (scalar @paths, 3, "Simple traverse A->D, correct number of elements");
    is_deeply ([sort {$a cmp $b} @paths], [qw(B C D)], "Simple traverse A->D, finding B,C,D");
}

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 3, "Traversal A->D weight");
}

{
    my $paths = $g->traverse([qw(B)],{hash => 1});
    is (ref $paths, 'HASH', "Detailed traversal returns hash");
    is ($paths->{D}->{weight}, 2, "Traversal B->D weight");
}

{
    my $paths = $g->traverse([qw(B)],{hash => 1, next => 'predecessors'});
    is (ref $paths, 'HASH', "Detailed traversal in reverse returns hash");
    is ($paths->{A}->{weight}, 1, "Traversal B->A weight");
    ok (!defined $paths->{C}, "Reverse traversal from B should not find C");
}

$g->add_path(qw(A E F G D Q)); 
$g->set_edge_attribute('E','F','weight',0.2);
$g->set_edge_attribute('F','G','weight',0.2);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight");
}

{
    my $paths = $g->traverse('B',{hash => 1});
    is ($paths->{D}->{weight}, 2, "Traversal B->D weight");
    is ($paths->{Q}->{weight}, 3, "Traversal B->Q weight");
}

# Set a high weight on a shortcut, to force recalculation of
# depth-first search
$g->add_path(qw(A D));
$g->set_edge_attribute('A','D', 'weight', 11.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight with one shortcut");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight with one shortcut");
}

$g->set_edge_attribute('A','C', 'weight', 17.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight with two shortcuts");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight with two shortcuts");
}

{
    my $paths = $g->traverse([qw(D)],{hash => 1, next => 'predecessors'});
    is ($paths->{A}->{weight}, 2.4, "Traversal D->A");
}

{
    my $paths = $g->traverse([qw(A)],{hash => 1, attribute => 'time', default => 10});
    is ($paths->{D}->{weight}, 10, "Traversal A->D using 'time' attribute");
    is ($paths->{Q}->{weight}, 20, "Traversal A->Q using 'time' attribute");
}

$g->set_edge_attribute('A','D', 'time', 0.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, attribute => 'time', default => 10});
    is ($paths->{B}->{weight},   10, "Traversal A->B using 'time' attribute");
    is ($paths->{C}->{weight},   10, "Traversal A->C using 'time' attribute");   # there is an A-C edge
    is ($paths->{D}->{weight},  0.3, "Traversal A->D using 'time' attribute");
    is ($paths->{Q}->{weight}, 10.3, "Traversal A->Q using 'time' attribute");   # A-D, D-Q.
    ok (!defined $paths->{Z}, "Traversal to undefined vertex");
}

$g->set_vertex_attribute('B', 'weight', 3);
$g->set_vertex_attribute('C', 'weight', 1);
$g->set_vertex_attribute('D', 'weight', 4);
$g->set_vertex_attribute('Q', 'weight', 1);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, vertex => 1, max => 4, default => 0});
    is ($paths->{B}->{weight},   3, "Traversal A->B using vertex weight");   # A has weight 0
    is ($paths->{C}->{weight},   1, "Traversal A->C using vertex weight");   # there is an A-C edge
    is ($paths->{D}->{weight},   4, "Traversal A->D using vertex weight");   # there is an A-D edge
    ok (!defined $paths->{Q}, "Traversal A->Q, with maximum vertex weight, should fail");
}

$g->set_vertex_attribute('Q', 'weight', undef);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, vertex => 1, max => 4, default => 0});
    is ($paths->{Q}->{weight},   4, "Traversal A->Q using vertex weight");   # A (weight=0), D (4), Q (0)
}

$g->add_cycle(qw(A X1 X2 X3));

{
    my $paths = $g->traverse('A',{hash => 1});
    is ($paths->{X3}->{weight}, 3, "Traversal of a graph with a cycle");
}


done_testing;

__END__

