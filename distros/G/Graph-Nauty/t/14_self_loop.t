use strict;
use warnings;
use Graph::Nauty qw( automorphism_group_size );
use Graph::Undirected;
use Test::More tests => 1;

my $g = Graph::Undirected->new;
$g->add_edge( 0, 0 );

eval { automorphism_group_size( $g ) };
ok $@ && $@ eq "cannot handle graphs with self-loops\n";
