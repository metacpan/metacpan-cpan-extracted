use strict;
use warnings;

use Chemistry::OpenSMILES::Parser;
use Graph::VF2 qw( matches );
use Test::More tests => 7;

my $parser = Chemistry::OpenSMILES::Parser->new;

my( $phenanthroline ) = $parser->parse( 'c1cc2ccc3cccnc3c2nc1' );
my( $phenanthrene ) = $parser->parse( 'C1=CC=C2C(=C1)C=CC3=CC=CC=C32' );
my( $benzene ) = $parser->parse( 'c1ccccc1' );

# Drop H atoms, otherwise there will be no matches
$benzene->delete_vertices( grep { $_->{symbol} eq 'H' } $benzene->vertices );

my $vertex_correspondence_sub;

$vertex_correspondence_sub = sub { ucfirst $_[0]->{symbol} eq ucfirst $_[1]->{symbol} };

is scalar matches( $benzene, $phenanthroline, { vertex_correspondence_sub => $vertex_correspondence_sub } ), 12;
is scalar matches( $benzene, $phenanthrene, { vertex_correspondence_sub => $vertex_correspondence_sub } ), 36;

# Require strict match of the chemical symbol
$vertex_correspondence_sub = sub { $_[0]->{symbol} eq $_[1]->{symbol} };

is scalar matches( $benzene, $phenanthroline, { vertex_correspondence_sub => $vertex_correspondence_sub } ), 12;
is scalar matches( $benzene, $phenanthrene, { vertex_correspondence_sub => $vertex_correspondence_sub } ), 0;

# Select all six-membered cycles

is scalar matches( $benzene, $phenanthroline ), 36;
is scalar matches( $benzene, $phenanthrene ), 36;

my $any_vertex = Graph::Undirected->new;
$any_vertex->add_vertex( 0 );

$vertex_correspondence_sub = sub { $_[1]->{symbol} =~ /^[CN]$/i };

is scalar matches( $any_vertex, $phenanthroline, { vertex_correspondence_sub => $vertex_correspondence_sub } ), 14;
