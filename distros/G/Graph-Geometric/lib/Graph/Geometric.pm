package Graph::Geometric;

use strict;
use warnings;
use feature qw(current_sub); # Perl v5.16 or later

=head1 NAME

Graph::Geometric - create and work with geometric graphs

=cut

# ABSTRACT: Create and work with geometric graphs
our $VERSION = '0.2.0'; # VERSION

use Exporter;
use Graph 0.9713;
use Graph::Undirected;

use parent Graph::Undirected::, Exporter::;

our @polygon_names = (
    '', 'mono', 'di', 'tri', 'tetra', 'penta', 'hexa', 'hepta', 'octa', 'nona', 'deca',
    'undeca', 'dodeca', 'trideca', 'tetradeca', 'pentadeca', 'hexadeca', 'heptadeca', 'octadeca', 'nonadeca',
    'icosa', 'henicosa', 'docosa', 'tricosa', 'tetracosa', 'pentacosa', 'hexacosa', 'heptacosa', 'octacosa', 'nonacosa',
    'triaconta', 'hentriaconta', 'dotriaconta', 'tritriaconta', 'tetratriaconta', 'pentatriaconta', 'hexatriaconta', 'heptatriaconta',
    'octatriaconta', 'nonatriaconta', 'tetraconta',
);
my @subs = qw(
    antiprism
    bifrustum
    bipyramid
    cucurbituril
    cupola
    dodecahedron
    gyrobicupola
    icosahedron
    icosidodecahedron
    octahedron
    orthobicupola
    prism
    pyramid
    rectified
    rhombic_dodecahedron
    rotunda
    stellated
    trapezohedron
    truncated
);
push @subs, map { $_ . 'gonal' } @polygon_names[1..$#polygon_names];
push @subs, 'triangular', 'square';

our @EXPORT = @subs;

use List::Util qw( all any max sum uniq );
use Set::Scalar;

sub AUTOLOAD {
    our $AUTOLOAD;
    my $call = $AUTOLOAD;
    $call =~ s/.*:://;
    return if $call eq 'DESTROY';
    if( $call =~ /gonal$/ ) {
        my $N = _polygon_name_to_number( $call );
        return unless defined $N;
        $_[0]->($N);
    } elsif( $call eq 'triangular' ) {
        $_[0]->(3);
    } elsif( $call eq 'square' ) {
        $_[0]->(4);
    } else {
        return;
    }
}

=head1 SYNOPSIS

    use Graph::Geometric;

    # Generate a truncated regular icosahedron
    my $g = icosahedron->truncated;

    # Count the faces
    print scalar $g->faces;

=head1 DESCRIPTION

C<Graph::Geometric> is an extension of L<Graph> to support working with geometric (topologic) graphs.
In addition to vertices and edges, C<Graph::Geometric> has a concept of faces to ease handling of geometric graphs.
C<Graph::Geometric> does not provide coordinates for vertices as it is supposed to be used for topology analysis of geometric shapes.

As of now, C<Graph::Geometric> does not allow for arbitrary graph construction.
Geometric graphs have to be built from simple polyhedra (constructors listed below) or derived from them by using modifiers such as stellation or truncation.
Removal of vertices and faces is also supported.

=head2 ON THE STABILITY OF API

As C<Graph::Geometric> is in its early stages of development, not much of API stability can be promised.
In particular, method names are likely to be changed for the sake of homogeneity.
Names of generated vertices and order of faces returned by C<faces()> as well are likely to change.
Some syntax sugar may also appear.

=head1 CONSTRUCTORS

=head2 C<antiprism( $N )>

Given N, creates an N-gonal antiprism.
If N is not given, returns a code reference to itself.

=cut

sub antiprism
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my @vertices = _names( $N * 2 );

    # Cap faces
    my @F1 = map { $vertices[$_] } grep { !($_ % 2) } 0..($N*2-1);
    my @F2 = map { $vertices[$_] } grep {   $_ % 2  } 0..($N*2-1);

    my $self = Graph::Undirected->new;
    $self->add_vertices( @vertices );

    $self->add_cycle( @F1 );
    $self->add_cycle( @F2 );
    $self->add_cycle( @vertices );

    my @faces = ( Set::Scalar->new( @F1 ), Set::Scalar->new( @F2 ) );
    for my $i (0..($N-1)) {
        push @faces, Set::Scalar->new( map { $vertices[($i*2+$_) % ($N*2)] } 0..2 );
        push @faces, Set::Scalar->new( map { $vertices[($i*2+$_) % ($N*2)] } 1..3 );
    }

    $self->set_graph_attribute( 'constructor', 'antiprism' );
    $self->set_graph_attribute( 'faces', \@faces );
    return bless $self;
}

=head2 C<bifrustum( $N )>

Given N, creates an N-gonal bifrustum.
If N is not given, returns a code reference to itself.
Since C<Graph::Geometric> does not provide coordinates, bifrustum is simply a prism with side faces cut in half.

=cut

sub bifrustum
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $prism = prism( $N );

    # Find top and bottom faces by the number of vertices in them
    # FIXME: The following is unstable in cubes
    my( $F1, $F2 ) = grep { scalar( @$_ ) == $N } $prism->faces;

    # Select size edges, Graph::subgraph() does not work somewhy
    my @side_edges;
    for ($prism->edges) {
        my $in_F1 = (Set::Scalar->new( @$F1 ) * Set::Scalar->new( @$_ ))->size;
        my $in_F2 = (Set::Scalar->new( @$F2 ) * Set::Scalar->new( @$_ ))->size;
        push @side_edges, $_ if $in_F1 && $in_F2;
    }

    # Carve side edges
    for( @side_edges ) {
        $prism->carve_edge( @$_ );
    }

    # Align vertices in both faces
    my @F1 = $prism->_cycle_in_order( @$F1 );
    my @F2;
    for my $vertex (@F1) {
        my( $edge ) = grep { $_->[0] eq $vertex || $_->[1] eq $vertex } @side_edges;
        push @F2, grep { $_ ne $vertex } @$edge;
    }

    # Carve all side faces
    for (0..($N-1)) {
        $prism->carve_face( join( '', sort ( $F1[$_], $F2[$_] ) ),
                            join( '', sort ( $F1[($_+1) % $N], $F2[($_+1) % $N] ) ) );
    }

    $prism->set_graph_attribute( 'constructor', 'bifrustum' );

    return $prism;
}

=head2 C<bipyramid( $N )>

Given N, creates an N-gonal bipyramid.
If N is not given, returns a code reference to itself.

=cut

sub bipyramid
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $pyramid = pyramid( $N );
    my( $base ) = $pyramid->faces;
    $pyramid->stellate( $base );
    $pyramid->set_graph_attribute( 'constructor', 'bipyramid' );
    return $pyramid;
}

=head2 C<cucurbituril( $N )>

Given N, creates a geometric graph representing chemical structure of cucurbit[N]uril.
Cucurbiturils do not exacly fit the definition of polyhedra, but have nevertheless interesting structures.
If N is not given, returns a cucurbit[5]uril, the smallest naturally occurring cucurbituril.

=cut

sub cucurbituril
{
    my( $N ) = @_;
    $N = 5 unless defined $N;

    my @vertices = _names( $N * 10 );

    my $self = Graph::Undirected->new;
    $self->add_vertices( @vertices );

    # Cap faces
    my( @CAP1, @CAP2 );

    my @faces;

    # For each of the clycouril units
    for (0..($N-1)) {
        my @F51 = ( @vertices[($_*10)   .. ($_*10+4)] );
        my @F52 = ( @vertices[($_*10+4) .. ($_*10+7)], $vertices[$_*10] );
        my @F8  = ( @vertices[($_*10+3) .. ($_*10+5)],
                    $vertices[$_*10+9],
                    $vertices[(($_+1)*10+7) % ($N * 10)],
                    $vertices[(($_+1)*10)   % ($N * 10)],
                    $vertices[(($_+1)*10+1) % ($N * 10)],
                    $vertices[$_*10+8] );
        $self->add_cycle( @F51 );
        $self->add_cycle( @F52 );
        $self->add_cycle( @F8 );
        push @faces, Set::Scalar->new( @F51 ),
                     Set::Scalar->new( @F52 ),
                     Set::Scalar->new( @F8 );

        push @CAP1, @vertices[($_*10+1)..($_*10+3)], $vertices[$_*10+8];
        push @CAP2, $vertices[$_*10+9], @vertices[($_*10+5)..($_*10+7)];
    }

    @faces = ( Set::Scalar->new( @CAP1 ),
               Set::Scalar->new( @CAP2 ),
               @faces );

    $self->set_graph_attribute( 'constructor', 'cucurbituril' );
    $self->set_graph_attribute( 'faces', \@faces );

    return bless $self;
}

=head2 C<cupola( $N )>

Given N, creates an N-gonal cupola.
If N is not given, returns a code reference to itself.

=cut

sub cupola
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $prism = prism( $N*2 );
    my( $face ) = grep { scalar( @$_ ) == $N*2 } $prism->faces;
    my @face = $prism->_cycle_in_order( @$face );
    while( @face ) {
        $prism->delete_edge( shift @face, shift @face );
    }
    $prism->set_graph_attribute( 'constructor', 'cupola' );
    return $prism;
}

=head2 C<dodecahedron()>

Creates a regular dodecahedron.

=cut

sub dodecahedron()
{
    my $pt = trapezohedron( 5 );
    $pt->truncate( 'A', 'B' );
    $pt->set_graph_attribute( 'constructor', 'dodecahedron' );
    return $pt;
}

=head2 C<gyrobicupola( $N )>

Given N, creates an N-gonal gyrobicupola.
If N is not given, returns a code reference to itself.
Implementation detail: gyrobicupola is constructed by creating a bifrustum and removing every second edge on top and bottom faces.

=cut

sub gyrobicupola
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $bifrustum = bifrustum( $N*2 );

    # All side vertices, and only them, have degree of 4
    my @side_vertices =
        $bifrustum->_cycle_in_order( grep { $bifrustum->degree( $_ ) == 4 }
                                          $bifrustum->vertices );

    # Top and bottom faces consist only of vertices of degree 3
    my( $F1, $F2 ) = grep { all { $bifrustum->degree( $_ ) == 3 } @$_ }
                          $bifrustum->faces;

    # Collect face vertices in the same order
    my( @F1, @F2 );
    for my $vertex (@side_vertices) {
        my( $v1, $v2 ) = grep { $bifrustum->degree( $_ ) == 3 }
                              $bifrustum->neighbours( $vertex );
        ( $v1, $v2 ) = ( $v2, $v1 ) if grep { $_ eq $v2 } @$F1;
        push @F1, $v1;
        push @F2, $v2;
    }

    push @F2, shift @F2;
    while( @F1 ) {
        $bifrustum->delete_edge( shift @F1, shift @F1 );
    }
    while( @F2 ) {
        $bifrustum->delete_edge( shift @F2, shift @F2 );
    }

    $bifrustum->set_graph_attribute( 'constructor', 'gyrobicupola' );

    return $bifrustum;
}

=head2 C<icosahedron()>

Creates a regular icosahedron.

=cut

sub icosahedron()
{
    return dodecahedron->dual;
}

=head2 C<icosidodecahedron()>

Creates an icosidodecahedron.

=cut

sub icosidodecahedron()
{
    return dodecahedron->rectify;
}

=head2 C<octahedron()>

Creates a regular octahedron.

=cut

sub octahedron()
{
    return bipyramid( 4 );
}

=head2 C<orthobicupola( $N )>

Given N, creates an N-gonal orthobicupola.
If N is not given, returns a code reference to itself.
Implementation detail: orthobicupola is constructed by creating a bifrustum and removing every second edge on top and bottom faces.

=cut

sub orthobicupola
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $bifrustum = bifrustum( $N*2 );

    # All side vertices, and only them, have degree of 4
    my @side_vertices =
        $bifrustum->_cycle_in_order( grep { $bifrustum->degree( $_ ) == 4 }
                                          $bifrustum->vertices );

    # Top and bottom faces consist only of vertices of degree 3
    my( $F1, $F2 ) = grep { all { $bifrustum->degree( $_ ) == 3 } @$_ }
                          $bifrustum->faces;

    # Collect face vertices in the same order
    my( @F1, @F2 );
    for my $vertex (@side_vertices) {
        my( $v1, $v2 ) = grep { $bifrustum->degree( $_ ) == 3 }
                              $bifrustum->neighbours( $vertex );
        ( $v1, $v2 ) = ( $v2, $v1 ) if grep { $_ eq $v2 } @$F1;
        push @F1, $v1;
        push @F2, $v2;
    }

    while( @F1 ) {
        $bifrustum->delete_edge( shift @F1, shift @F1 );
    }
    while( @F2 ) {
        $bifrustum->delete_edge( shift @F2, shift @F2 );
    }

    $bifrustum->set_graph_attribute( 'constructor', 'orthobicupola' );
    return $bifrustum;
}

=head2 C<prism( $N )>

Given N, creates an N-gonal prism.
If N is not given, returns a code reference to itself.

=cut

sub prism
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my @vertices = _names( $N * 2 );
    my @F1 = @vertices[0..($N-1)];
    my @F2 = @vertices[$N..$#vertices];

    my $self = Graph::Undirected->new;
    my @faces;
    $self->add_cycle( @F1 );
    $self->add_cycle( @F2 );
    push @faces, Set::Scalar->new( @F1 ), Set::Scalar->new( @F2 );

    for (0..($N-1)) {
        $self->add_edge( $F1[$_], $F2[$_] );
        push @faces, Set::Scalar->new( $F1[$_], $F2[$_],
                                       $F1[($_+1) % $N],
                                       $F2[($_+1) % $N] );
    }

    $self->set_graph_attribute( 'constructor', 'prism' );
    $self->set_graph_attribute( 'faces', \@faces );

    return bless $self;
}

=head2 C<pyramid( $N )>

Given N, creates an N-gonal pyramid.
If N is not given, returns a code reference to itself.

=cut

sub pyramid
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my @vertices = _names( $N + 1 );
    my( $apex, @base ) = @vertices;

    my $self = Graph::Undirected->new;
    my @faces;
    $self->add_vertices( @vertices );
    $self->add_cycle( @base );
    push @faces, Set::Scalar->new( @base );

    for (0..($N-1)) {
        $self->add_edge( $apex, $base[$_] );
        push @faces, Set::Scalar->new( $apex,
                                       $base[$_],
                                       $base[($_+1) % $N] );
    }

    $self->set_graph_attribute( 'constructor', 'pyramid' );
    $self->set_graph_attribute( 'faces', \@faces );

    return bless $self;
}

=head2 C<rhombic_dodecahedron()>

Creates a rhombic dodecahedron.

=cut

sub rhombic_dodecahedron()
{
    return octahedron->rectify->dual;
}

=head2 C<rotunda( $N )>

Given N, creates an N-gonal rotunda.
If N is not given, returns a code reference to itself.

=cut

sub rotunda
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my $cupola = cupola( $N );
    my $face;
    for ($cupola->faces) {
        next unless scalar( @$_ ) == $N;
        next unless sum( map { $cupola->degree($_) } @$_ ) == $N*4;
        $face = $_;
        last;
    }
    $cupola->face_dualify( @$face );
    $cupola->set_graph_attribute( 'constructor', 'rotunda' );

    return $cupola;
}

=head2 C<tetrahedron()>

Creates a regular tetrahedron.

=cut

sub tetrahedron()
{
    my @vertices = 'A'..'D';

    my $self = Graph::Undirected->new;
    $self->add_vertices( @vertices );

    my @faces;
    for my $v1 (@vertices) {
        for my $v2 (@vertices) {
            next if $v1 eq $v2;
            $self->add_edge( $v1, $v2 );
        }

        push @faces, Set::Scalar->new( grep { $_ ne $v1 } @vertices );
    }

    $self->set_graph_attribute( 'constructor', 'pyramid' );
    $self->set_graph_attribute( 'faces', \@faces );

    return bless $self; # TODO: Bless with class?
}

=head2 C<trapezohedron( $N )>

Creates an N-gonal trapezohedron.
If N is not given, returns a code reference to itself.

=cut

sub trapezohedron
{
    my( $N ) = @_;
    return __SUB__ unless defined $N;

    my @vertices = _names( $N * 2 + 2 );

    my $self = Graph::Undirected->new;
    $self->add_vertices( @vertices );
    my( $apex1, $apex2, @equator ) = @vertices;
    $self->add_cycle( @equator );

    for (0..$#equator) {
        $self->add_edge( $equator[$_],
                         (($_+1) % 2 ? $apex1 : $apex2) );
    }

    my @faces;
    for my $i (0..$N-1) {
        push @faces, Set::Scalar->new( $apex1,
                                       map { $equator[($i*2+$_) % ($N*2)] } 0..2 );
        push @faces, Set::Scalar->new( $apex2,
                                       map { $equator[($i*2+$_) % ($N*2)] } 1..3 );
    }

    $self->set_graph_attribute( 'constructor', 'trapezohedron' );
    $self->set_graph_attribute( 'faces', \@faces );
    return bless $self; # TODO: Bless with class?
}

=head1 ACCESSORS

=head2 C<faces( @vertices )>

Returns an array of arrays listing vertices in each of polyhedron's faces.
Vertex lists are returned sorted, they do not maintain the order of vertices in faces.
Experimental: given a list of vertices, select only faces containing all of them.

=cut

sub faces
{
    my( $self, @vertices ) = @_;

    my @faces = @{$self->get_graph_attribute( 'faces' )};
    if( @vertices ) {
        # Set::Scalar::is_subset() fails as of 1.29 for unknown reasons
        my @faces_now;
        for my $face (@faces) {
            push @faces_now, $face if all { $face->has( $_ ) } @vertices;
        }
        @faces = @faces_now;
    }

    return map { [ sort $_->members ] } @faces;
}

=head1 GRAPH METHODS

=head2 C<deep_copy()>

Creates a deep copy of a Graph::Geometric object.

=cut

sub deep_copy
{
    my( $self ) = @_;
    my $copy = $self->SUPER::deep_copy;
    return bless $copy; # FIXME: Bless with the same class
}

=head2 C<delete_edge( $u, $v )>

Deletes an edge by merging its vertices.
Given edge is assumed to exist, a check will be implemented later.
Modifies and returns the original object.

=cut

sub delete_edge
{
    my( $self, $vertex1, $vertex2 ) = @_;
    return $self unless $self->has_edge( $vertex1, $vertex2 );

    my @neighbours = ( $self->neighbours( $vertex1 ),
                       $self->neighbours( $vertex2 ) );
    $self->SUPER::delete_vertex( $vertex1 ); # delete_vertices() does not work
    $self->SUPER::delete_vertex( $vertex2 );

    my $vertex = join '', sort ( $vertex1, $vertex2 );
    $self->_ensure_vertices_do_not_exist( $vertex );

    for (@neighbours) {
        next if $_ eq $vertex1;
        next if $_ eq $vertex2;
        $self->add_edge( $vertex, $_ );
    }

    my @faces;
    for (@{$self->get_graph_attribute( 'faces' )}) {
        if( $_->has( $vertex1 ) ) {
            $_->delete( $vertex1 );
            $_->insert( $vertex );
        }
        if( $_->has( $vertex2 ) ) {
            $_->delete( $vertex2 );
            $_->insert( $vertex );
        }
        push @faces, $_ if $_->size > 2; # Exclude collapsed faces
    }

    $self->delete_graph_attribute( 'constructor' );
    $self->set_graph_attribute( 'faces', \@faces );

    return $self;
}

=head2 C<delete_face( $face )>

Deletes a given face from polyhedra.
A face is defined by an unordered list of vertices.
Does nothing if a given face does not exist.
Modifies and returns the original object.

=cut

sub delete_face
{
    my( $self, $face ) = @_;
    return $self unless $self->has_face( $face );

    my $vertex = join '', sort @$face;
    $self->_ensure_vertices_do_not_exist( $vertex );
    $self->add_vertex( $vertex );

    for my $member (@$face) {
        for my $neighbour ($self->neighbours( $member )) {
            $self->add_edge( $neighbour, $vertex );
        }
    }

    $self->SUPER::delete_vertices( @$face );

    my $face_set = Set::Scalar( @$face );
    my @faces = grep { !$face_set->is_equal( $_ ) }
                     @{$self->get_graph_attribute( 'faces' )};
    for (@faces) {
        next if $face_set->is_disjoint( $_ );
        $_->delete( @$face );
        $_->insert( $vertex );
    }

    $self->delete_graph_attribute( 'constructor' );
    $self->set_graph_attribute( 'faces', \@faces );

    return $self;
}

=head2 C<delete_vertex( $v )>

Handles vertex deletion by merging neighbouring faces.
Modifies and returns the original object.

=cut

sub delete_vertex
{
    my( $self, $vertex ) = @_;
    $self->SUPER::delete_vertex( $vertex );

    my @containing_faces = grep {  $_->has( $vertex ) }
                                @{$self->get_graph_attribute( 'faces' )};
    my @other_faces      = grep { !$_->has( $vertex ) }
                                @{$self->get_graph_attribute( 'faces' )};

    return $self unless @containing_faces;

    my $new_face = sum( @containing_faces );
    $new_face->delete( $vertex );

    $self->delete_graph_attribute( 'constructor' );
    $self->set_graph_attribute( 'faces', [ @other_faces, $new_face ] );

    return $self;
}

=head2 C<has_face( $face )>

Returns true if a given face exists, false otherwise.

=cut

sub has_face
{
    my( $self, $face ) = @_;
    $face = join ',', sort @$face;
    return any { join( ',', sort @$_ ) eq $face }
               @{$self->get_graph_attribute( 'faces' )};
}

=head1 GEOMETRIC METHODS

=cut

sub carve_edge
{
    my( $self, @edge ) = @_;

    $self->SUPER::delete_edge( @edge );
    my $vertex = join '', sort @edge;
    $self->_ensure_vertices_do_not_exist( $vertex );

    # Add new vertex in between the given ones
    $self->add_path( $edge[0], $vertex, $edge[1] );

    # Update all faces containing the edge to also have the new vertex
    for (@{$self->get_graph_attribute( 'faces' )}) {
        next unless $_->has( $edge[0] ) && $_->has( $edge[1] );
        $_->insert( $vertex );
    }

    $self->delete_graph_attribute( 'constructor' );

    return $self;
}
=head2 C<carve_face( $u, $v )>

Given a graph and a pair of vertices lying on the same face, add a new edge splitting the face in two.
Subroutine dies if there is no face containing both vertices.

=cut

sub carve_face
{
    my( $self, @edge ) = @_;
    return $self if $self->has_edge( @edge ); # has edge already

    # Find a face containing both vertices, filter it out from face list
    my @faces;
    my $face;
    for (@{$self->get_graph_attribute( 'faces' )}) {
        if( $_->has( $edge[0] ) && $_->has( $edge[1] ) ) {
            $face = $_;
        } else {
            push @faces, $_;
        }
    }
    if( !$face ) {
        local $" = ' and ';
        die "there is no face having both @edge vertices\n";
    }
    my @face = $self->_cycle_in_order( $face->members );

    $self->add_edge( @edge );

    # "Rewind" the vertices in cycle to start with the first joined vertex
    while( $face[0] ne $edge[0] ) {
        push @face, shift @face;
    }
    # Store all vertices in @F1 until the second joined vertex is reached
    my @F1;
    while( $face[0] ne $edge[1] ) {
        push @F1, shift @face;
    }
    push @F1, $edge[1];
    my @F2 = ( @face, $edge[0] );

    push @faces, Set::Scalar->new( @F1 ), Set::Scalar->new( @F2 );
    $self->set_graph_attribute( 'faces', \@faces );

    $self->delete_graph_attribute( 'constructor' );

    return $self;
}

=head2 C<elongate( $cycle )>

Elongate the given polyhedron.
If given a face, elongates the polyhedron by extruding it.
If given a non-face cycle, elongates the polyhedron by cutting accross the given cycle and inserting a prism in between.
If not given anything, attempts to elongate according to the type of given polyhedron.
I.e., pyramids are elongated by extruding their faces and so on.
Subroutine dies if it encounters a polyhedron of a type unknown to it.

=cut

sub elongate
{
    my( $self, $cycle ) = @_;

    if( $cycle && $self->has_face( $cycle ) ) {
        # Elongate along the given face
        my @face = $self->_cycle_in_order( @$cycle );
        my @vertices = map { $_ . 'e' } @face;
        $self->_ensure_vertices_do_not_exist( @vertices );
        $self->add_cycle( @vertices );

        my @faces;
        for my $face (@{$self->get_graph_attribute( 'faces' )}) {
            next if join( '', sort $face->members ) eq join( '', sort @face );
            push @faces, $face;
        }

        for my $i (0..$#face) {
            $self->add_edge( $face[$i], $face[$i] . 'e' );
            push @faces, Set::Scalar->new( $face[$i],
                                           $face[$i] . 'e',
                                           $face[($i+1) % @face],
                                           $face[($i+1) % @face] . 'e' );
        }
        push @faces, Set::Scalar->new( @vertices );

        $self->set_graph_attribute( 'faces', \@faces );
    } elsif( $cycle ) {
        # Elongate along the given cut
        if( !$self->has_cycle( @$cycle ) ) {
            die "cannot elongate nonexisting cycle\n";
        }

        my @cycle = $self->_cycle_in_order( @$cycle );
        my $copy = $self->copy;
        for (@cycle) { $copy->SUPER::delete_vertex( $_ ) } # delete_vertices() does not work
        my( $C1, $C2 ) = $copy->connected_components; # FIXME: Establish deterministic order

        my @vertices1 = map { $_ . '1' } @cycle;
        my @vertices2 = map { $_ . '2' } @cycle; # FIXME: Check new vertices

        $self->add_cycle( @vertices1 );
        $self->add_cycle( @vertices2 );

        my $cycle_set = Set::Scalar->new( @cycle );
        for my $face (@{$self->get_graph_attribute( 'faces' )}) {
            my @vertices = ($face * $cycle_set)->elements;
            next unless @vertices;

            # The remaining vertices in a face will belong either to $C1 or $C2
            my( $vertex ) = ($face - $cycle_set)->elements;
            if( any { $_ eq $vertex } @$C1 ) {
                $face->invert( @vertices, map { $_ . '1' } @vertices );
            } else {
                $face->invert( @vertices, map { $_ . '2' } @vertices );
            }
        }

        my @new_faces;
        for (0..$#cycle) {
            $self->add_edge( $vertices1[$_], $vertices2[$_] );
            push @new_faces, Set::Scalar->new( $vertices1[$_],
                                               $vertices2[$_],
                                               $vertices1[($_+1) % @cycle],
                                               $vertices2[($_+1) % @cycle] );
        }

        for my $cycle_vertex (@cycle) {
            for my $neighbour ($self->neighbours( $cycle_vertex )) {
                if(      any { $_ eq $neighbour } @$C1 ) {
                    $self->add_edge( $neighbour, $cycle_vertex . '1' );
                } elsif( any { $_ eq $neighbour } @$C2 ) {
                    $self->add_edge( $neighbour, $cycle_vertex . '2' );
                }
            }
        }

        for (@cycle) { $self->SUPER::delete_vertex( $_ ) } # delete_vertices() does not work
        $self->set_graph_attribute( 'faces', [ @{$self->get_graph_attribute( 'faces' )},
                                               @new_faces ] );
    } else {
        # Elongate according to the type of geometric figure
        if( !$self->has_graph_attribute( 'constructor' ) ) {
            die "unknown geometric type for elongation\n";
        }

        my $constructor = $self->get_graph_attribute( 'constructor' );

        if(      $constructor eq 'bipyramid' ) {
            # FIXME: May be nondeterministic for square bipyramids
            my @cycle = grep { $self->degree( $_ ) == 4 } $self->vertices;
            $self->elongate( \@cycle );
        } elsif( $constructor eq 'cupola' ||
                 $constructor eq 'pyramid' ||
                 $constructor eq 'rotunda' ) {
            # Elongate (extrude) the largest face
            my( $face ) = sort { scalar( @$b ) <=> scalar( @$a ) } $self->faces;
            $self->elongate( $face );
        } elsif( $constructor eq 'gyrobicupola' ||
                 $constructor eq 'orthobicupola' ) {
            # Bicupolae are elongated along cycle where every vertex belongs to two triangular faces
            my %triangular_faces;
            for my $face ($self->faces) {
                next unless scalar( @$face ) == 3;
                for (@$face) {
                    $triangular_faces{$_} = 0 unless $triangular_faces{$_};
                    $triangular_faces{$_}++;
                }
            }

            my @cycle = grep { $triangular_faces{$_} == 2 } keys %triangular_faces;
            $self->elongate( \@cycle );
        } elsif( $constructor eq 'gyrobirotunda' ||
                $constructor eq 'orthobirotunda' ) {
            # Birotundas should have two faces that are neither triangles nor pentagons.
            # FIXME: Will fail with trigonal and pentagonal birotundas.
            my @bases = grep { scalar( @$_ ) != 3 && scalar( @$_ ) != 5 }
                             $self->faces;
            my @removed = uniq @bases, map { $self->neighbours( $_ ) } @bases;
            my $copy = $self->copy;
            for (@removed) { $copy->SUPER::delete_vertex( $_ ) }
            $self->elongate( [ $copy->vertices ] );
        } else {
            die "do not know how to elongate $constructor\n";
        }
    }

    $self->delete_graph_attribute( 'constructor' );
    return $self;
}

sub face_dualify
{
    my( $self, @face ) = @_;

    # Remove the to-be-dualified face
    my @faces;
    for my $face (@{$self->get_graph_attribute( 'faces' )}) {
        next if join( '', sort $face->members ) eq join( '', sort @face );
        push @faces, $face;
    }

    @face = $self->_cycle_in_order( @face );
    my @new_vertices;
    for (0..$#face) {
        my @edge = sort ( $face[$_], $face[($_+1) % scalar @face] );
        $self->carve_edge( @edge );
        my $vertex = join '', @edge;
        push @new_vertices, join '', @edge;
        push @faces, Set::Scalar->new( $vertex, @edge );
    }
    $self->add_cycle( @new_vertices );
    push @faces, Set::Scalar->new( @new_vertices );

    $self->set_graph_attribute( 'faces', \@faces );
    $self->delete_graph_attribute( 'constructor' );

    return $self;
}

=head2 C<rectify()>

Given a polyhedron, performs its rectification.
Modifies and returns the original object.

=cut

sub rectify
{
    my( $self ) = @_;

    # Preserve the original list of vertices
    my @vertices = $self->vertices;

    # Carve all the edges
    for ($self->edges) {
        $self->carve_edge( @$_ );
    }

    # Cut off the original vertices
    for my $vertex (@vertices) {
        # Carve all adjacent faces
        for my $face ($self->faces( $vertex )) {
            my( $A, $B ) = grep { $self->has_edge( $vertex, $_ ) } @$face;
            $self->carve_face( $A, $B );
        }

        # Delete the vertex and merge adjacent faces
        $self->delete_vertex( $vertex );
    }

    $self->delete_graph_attribute( 'constructor' );

    return $self;
}

=head2 C<stellate( @faces )>

Given a polyhedron and a list of faces, performs stellation of specified faces.
If no faces are given, all faces are stellated.
Modifies and returns the original object.

=cut

sub stellate
{
    my( $self, @faces ) = @_;
    @faces = $self->faces unless @faces;

    my @faces_now;
    for my $face ($self->faces) {
        if( grep { join( '', sort @$face ) eq join( '', sort @$_ ) } @faces ) {
            # This face has been requested to be stellated
            my $center = join '', @$face;
            $self->_ensure_vertices_do_not_exist( $center );
            $self->add_vertex( $center );
            for my $vertex (@$face) {
                $self->add_edge( $center, $vertex );
            }

            for my $edge ($self->subgraph( $face )->edges) {
                push @faces_now, Set::Scalar->new( $center, @$edge );
            }
        } else {
            # This face has not been requested to be stellated
            push @faces_now, Set::Scalar->new( @$face );
        }
    }

    $self->delete_graph_attribute( 'constructor' );
    $self->set_graph_attribute( 'faces', \@faces_now );

    return $self;
}

=head2 C<truncate( @vertices )>

Given a polyhedron and a list of vertices, performs truncation of specified vertices.
If no vertices are given, all vertices are stellated.
Modifies and returns the original object.

=cut

sub truncate
{
    my( $self, @vertices ) = @_;
    @vertices = $self->vertices unless @vertices;

    for my $vertex (@vertices) {
        # Cut all the edges
        for my $neighbour ($self->neighbours( $vertex )) {
            $self->_ensure_vertices_do_not_exist( $vertex . $neighbour );
            $self->add_edge( $neighbour, $vertex . $neighbour );
        }

        # Trim all the faces
        for my $face_id (0..scalar( $self->faces ) - 1) {
            my $face = $self->get_graph_attribute( 'faces' )->[$face_id];
            next unless $face->has( $vertex );

            # Find the two neighbours of $vertex in the face
            my( $v1, $v2 ) = grep { $face->has( $_ ) } $self->neighbours( $vertex );

            # Connect the new vertices corresponding to edges with these neighbours
            $self->add_edge( $vertex . $v1, $vertex . $v2 );

            # Adjust the face
            $face->invert( $vertex, $vertex . $v1, $vertex . $v2 );
        }

        # Add new face created by trimming this one
        push @{$self->get_graph_attribute( 'faces' )},
             Set::Scalar->new( map { $vertex . $_ } $self->neighbours( $vertex ) );

        # Remove the vertex
        $self->SUPER::delete_vertex( $vertex );
    }

    $self->delete_graph_attribute( 'constructor' );

    return $self;
}

=head2 C<dual()>

Given a polyhedron, returns its dual as a new object.
The original object is not modified.

=cut

sub dual
{
    my( $self ) = @_;

    my $dual = Graph::Undirected->new;

    # All faces become vertices
    $dual->add_vertices( map { join '', @$_ } $self->faces );

    for my $face1_id (0..scalar( $self->faces ) - 1) {
        my $face1 = $self->get_graph_attribute( 'faces' )->[$face1_id];

        my $edges = {};
        for ($self->subgraph( [$face1->members] )->edges) {
            my @edges = sort @$_;
            $edges->{$edges[0]}{$edges[1]} = 1;
        }

        for my $face2_id ($face1_id+1..scalar( $self->faces ) - 1) {
            my $face2 = $self->get_graph_attribute( 'faces' )->[$face2_id];

            # If faces share an edge, they are connected in the dual
            for ($self->subgraph( [$face2->members] )->edges) {
                my @edges = sort @$_;
                next unless $edges->{$edges[0]}{$edges[1]};

                $dual->add_edge( join( '', sort $face1->members ),
                                 join( '', sort $face2->members ) );
                last;
            }
        }
    }

    my @dual_faces;
    for my $vertex ($self->vertices) {
        my @faces = grep { $_->has( $vertex ) }
                         @{$self->get_graph_attribute( 'faces' )};
        push @dual_faces,
             Set::Scalar->new( map { join '', sort $_->members } @faces );
    }

    $dual->set_graph_attribute( 'faces', \@dual_faces );

    return bless $dual; # TODO: Bless with a class
}

=head1 OPERATORS

The following class methods take a single Graph::Geometric object, copy it, perform a certain operation and return the results.
They allow for such syntactically sweet calls like:

    my $cuboctahedron1 = rectified tetragonal prism;
    my $cuboctahedron2 = rectified octahedron;

    my $truncated_icosahedron = truncated icosahedron;

=head2 C<elongated()>

Copies the given polyhedron, elongates it and returns the elongated polyhedron.
This subroutine does not accept any parameters, thus if nonstandard elongation is wanted, other methods have to be used.

=cut

sub elongated($)
{
    return $_[0]->deep_copy->elongate;
}

=head2 C<rectified()>

Copies the given polyhedron, rectifies it and returns the rectified polyhedron.

=cut

sub rectified($)
{
    return $_[0]->deep_copy->rectify;
}

=head2 C<stellated()>

Copies the given polyhedron, stellates all its faces and returns the stellated polyhedron.

=cut

sub stellated($)
{
    return $_[0]->deep_copy->stellate;
}

=head2 C<truncated()>

Copies the given polyhedron, truncates all its vertices and returns the truncated polyhedron.

=cut

sub truncated($)
{
    return $_[0]->deep_copy->truncate;
}

=head1 PROPERTIES

=head2 C<is_isogonal()>

Tests if a given polyhedron is isogonal (vertex-transitive) by checking whether all its vertices belong to the same symmetry orbit.
Requires L<Graph::Nauty> to locate symmetry orbits of a graph.

=cut

sub is_isogonal
{
    my( $self ) = @_;
    require Graph::Nauty;
    return scalar( Graph::Nauty::orbits( $self, sub { return '' } ) ) == 1;
}

=head2 C<is_isotoxal()>

Tests if a given polyhedron is isotoxal (edge-transitive) by checking whether all its edges belong to the same symmetry orbit.
Requires L<Graph::Nauty> to locate symmetry orbits of a graph.
Implementation detail: figure is rectified and tested for being isogonal.

=cut

sub is_isotoxal
{
    my( $self ) = @_;
    return $self->rectified->is_isogonal;
}

=head2 C<is_isohedral()>

Tests if a given polyhedron is isohedral (face-transitive) by checking whether all its faces belong to the same symmetry orbit.
Requires L<Graph::Nauty> to locate symmetry orbits of a graph.
Implementation detail: dual of a figure is tested for being isogonal.

=cut

sub is_isohedral
{
    my( $self ) = @_;
    return $self->dual->is_isogonal;
}

=head2 C<is_regular()>

Tests if given polyhedron is regular.
A regular polyhedron is vertex-transitive, edge-transitive and face-transitive.
Requires L<Graph::Nauty> to locate symmetry orbits of a graph.

=cut

sub is_regular
{
    my( $self ) = @_;
    return $self->is_isogonal && $self->is_isotoxal && $self->is_isohedral;
}

=head2 C<is_quasiregular()>

Tests if given quasiregular is regular.
A quasiregular polyhedron is vertex-transitive and edge-transitive, has two kinds of faces.
Requires L<Graph::Nauty> to locate symmetry orbits of a graph.

=cut

sub is_quasiregular
{
    my( $self ) = @_;
    return $self->is_isogonal && $self->is_isotoxal &&
           scalar( Graph::Nauty::orbits( $self->dual, sub { return '' } ) ) == 2;
}

sub _cycle_in_order
{
    my( $graph, @face ) = @_;
    my $subgraph = $graph->subgraph( \@face );
    my @order;
    my( $current ) = sort $subgraph->vertices;
    while( $subgraph->vertices ) {
        my( $next ) = sort $subgraph->neighbours( $current );
        push @order, $current;
        $subgraph->SUPER::delete_vertex( $current );
        $current = $next;
    }
    return @order;
}

sub _ensure_vertices_do_not_exist
{
    my( $graph, @vertices ) = @_;
    for (@vertices) {
        die "vertex $_ already exists\n" if $graph->has_vertex( $_ );
    }
}

sub _largest_face
{
    my( $self ) = @_;
    my $max;
    for ($self->faces) {
        next if defined $max && scalar( @$_ ) <= scalar( @$max );
        $max = $_;
    }
    return @$max;
}

sub _names
{
    my( $N ) = @_;

    my $n_letters = int( log( $N ) / log( 27 ) ) + 1;
    my $name = 'A' x $n_letters;
    my @names;
    for (1..$N) {
        push @names, $name;
        $name++;
    }

    return @names;
}

# TODO: Implement according to https://en.wikipedia.org/wiki/Polygon#Naming
# Not all synonyms are supported yet.
sub _polygon_name_to_number
{
    my( $name ) = @_;
    $name =~ s/gon(al)?$//;
    my( $number ) = grep { $name eq $polygon_names[$_] } 0..$#polygon_names;
    return $number;
}

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
