# $Id: Traverse.pm,v 1.8 2006/05/06 18:56:21 gene Exp $
package GraphViz::Traverse;
use strict;
use warnings;
use base qw( GraphViz );
use Carp;
our $VERSION = '0.02';
our $AUTOLOAD;

sub new {
    my( $proto, %args ) = @_;
    my $class = ref( $proto ) || $proto;
    my $self = $proto->SUPER::new( %args );

    $self->{_DEBUG} = $args{_DEBUG};

    $self->{_attributes} = {
        ( map { 'node_' . $_ => undef } qw(
            color
            distortion
            fillcolor
            fixedsize
            fontcolor
            fontname
            fontsize
            height
            href
            label
            layer
            orientation
            peripheries
            regular
            shape
            sides
            skew
            style
            target
            tooltip
            URL
            width
        ) ),
        ( map { 'edge_' . $_ => undef } qw(
            arrowhead
            arrowsize
            arrowtail
            color
            constraint
            decorate
            dir
            fontcolor
            fontname
            fontsize
            headURL
            headclip
            headhref
            headlabel
            headtarget
            headtooltip
            href
            label
            labelangle
            labeldistance
            layer
            minlen
            port_label_distance
            samehead
            sametail
            style
            tailURL
            tailclip
            tailhref
            taillabel
            tailtooltip
            target
            tooltip
            URL
            weight
        ) )
    };

    bless $self, $class;
    return $self;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref( $self ) || croak "$self is not an object";
    ( my $method = $AUTOLOAD ) =~ s/.*://;
    my $superior = "SUPER::$method";
    return exists $self->{_attributes}{$method}
        ? undef : $self->$superior(@_);
}

sub build_attributes {
    my( $self, $A, $B ) = @_;
    my $type = $B ? 'edge' : 'node';
    my %attributes = ();
    for my $method ( keys %{ $self->{_attributes} } ) {
        $self->{_attributes}{$method} = $B
            ? $self->$method( $A => $B )
            : $self->$method( $A );
    }
    return %{ $self->{_attributes} };
}

sub mark_item {
    my( $self, $node, $parent ) = @_;
    if( $parent ) {
        $self->add_edge( $parent => $node,
            $self->build_attributes( $node, $parent )
        );
    }
    else {
        $self->add_node( $node, $self->build_attributes( $node ) );
    }
}

sub traverse {
    my $self = shift;
    warn "traverse() must be overridden.\n" if $self->{_DEBUG};
    return undef;
}

1;

__END__

=head1 NAME

GraphViz::Traverse - Build a GraphViz object via callback traversal

=head1 SYNOPSIS

  use GraphViz::Traverse;

=head1 DESCRIPTION

A C<GraphViz::Traverse> object represents a base class for inheriting
by other traversal modules.

=head1 PUBLIC METHODS

=head2 new

  my $g = GraphViz::Traverse->new($arguments);

Return a new GraphViz::Traverse instance.  Valid arguments are listed
below (taken from C<man dot> and L<GraphViz::Traverse>):

  _DEBUG       = Class instance setting
  bgcolor      = Class instance setting
  center       = n a non-zero value centers the drawing on the page.
  color        = color value sets foreground color (bgcolorfor background).
  concentrate  = Class instance setting
  directed     = Class instance setting
  epsilon      = Class instance setting
  height       = Class instance setting
  href         = "url" the default url for image map files; in PostScript files, the base URL for all relative URLs, as recognized by Acrobat Distiller 3.0 and up.
  layers       = "id:id:id:id" is a sequence of layer identifiers for overlay diagrams. The PostScript array variable layercolorseqsets the assignment of colors to layers. The least indexis1and each element must be a 3-ele- ment array to be interpreted as a color coordinate.
  layout       = Class instance setting
  margin       = f sets the page margin (included in the page size).
  no_overlap   = Class instance setting
  nodesep      = f sets the minimum separation between nodes.
  nslimit      = f ormclimit=f adjusts the bound on the number of network simplexormincross iterations by the givenratio. For example,mclimit=2.0runs twice as long.
  ordering     = out constrains order of out-edges in a subgraph according to their file sequence.
  overlap      = Class instance setting
  page         = "x,y" sets the PostScript pagination unit.
  pagedir      = [TBLR][TBLR] sets the major and minor order of pagination.
  pageheight   = Class instance setting
  pagewidth    = Class instance setting
  random_start = Class instance setting
  rank         = same (or minor max) inasubgraph constrains the rank assignment of its nodes. If a subgraph's name has the prefixcluster, its nodes are drawn in a distinct rectangle of the layout. Clusters may be nested.
  rankdir      = LR|RL|BT requests a left-to-right, right-to-left, or bottom-to-top, drawing.
  ranksep      = f sets the minimum separation between ranks.
  ratio        = f sets the aspect ratio tof which may be a floating point number, orone of the keywordsfill, compress,orauto.
  rotate       = 90 sets landscape mode. (orientation=landis backward compatible but obsolete.)
  size         = "x,y" sets bounding box of drawing in inches.
  stylesheet   = "file.css" includes a reference to a stylesheet in -Tsvg and -Tsvgz outputs. Ignored by other formats.
  URL          = "url" ("URL" is a synonym for "href".)
  width        = Class instance setting

=head2 mark_item

  $g->mark_item( $node );
  $g->mark_item( $child, $parent );

Add a node or an edge to the C<GraphViz::Traverse> object.  This
method is to be used by the C<traverse> method.

=head2 traverse

  $g->traverse($root);

Traverse a structure starting at a given root node.  This method is to
be overridden by an inheriting class with specific traversal actions
for the C<GraphViz> C<dot> attributes listed below.  Please see
L<GraphViz::Traverse::Filesystem> for an example of this attribute
overriding.

Node attributes:

  color
  distortion
  fillcolor
  fixedsize
  fontcolor
  fontname
  fontsize
  height
  href
  label
  layer
  orientation
  peripheries
  regular
  shape
  sides
  skew
  style
  target
  tooltip
  URL
  width

Edge attributes:

  arrowhead
  arrowsize
  arrowtail
  color
  constraint
  decorate
  dir
  fontcolor
  fontname
  fontsize
  headURL
  headclip
  headhref
  headlabel
  headtarget
  headtooltip
  href
  label
  labelangle
  labeldistance
  layer
  minlen
  port_label_distance
  samehead
  sametail
  style
  tailURL
  tailclip
  tailhref
  taillabel
  tailtooltip
  target
  tooltip
  URL
  weight

=head1 TO DO

Document this code better.

=head1 THANK YOU

Brad Choate E<lt>bchoate@cpan.orgE<gt> for untangling my AUTOLOADing.

=head1 SEE ALSO

L<GraphViz>

L<GraphViz::Traverse::Filesystem>

=head1 COPYRIGHT

Copyright 2006, Gene Boggs, All Rights Reserved

You may use this module under the license terms of the parent
L<GraphViz> package.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=cut
