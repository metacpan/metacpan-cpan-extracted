# $Id: Filesystem.pm,v 1.4 2006/05/06 18:56:21 gene Exp $
package GraphViz::Traverse::Filesystem;
our $VERSION = '0.02';
use strict;
use warnings;
use Carp;
use base qw( GraphViz::Traverse );
use File::Find;
use File::Basename;

sub edge_color { return 'gray' }

sub traverse {
    my( $self, $root ) = @_;
    my $flag_item = sub {
        return if $_ eq '.';
        my $node = $File::Find::name;
        my( $name, $path ) = File::Basename::fileparse( $node );
        $path =~ s/\S$//;
        my $parent = File::Basename::fileparse( $path );
        warn "$node -> $path + $_\n\tL> $parent + $name\n"
            if $self->{_DEBUG};
        $self->mark_item( $node, $path );
    };
    File::Find::find( $flag_item, $root ); 
    return 1;
}

1;

__END__

=head1 NAME

GraphViz::Traverse::Filesystem - Visualize a filesystem with GraphViz

=head1 SYNOPSIS

  use GraphViz::Traverse::Filesystem;
  $g = GraphViz::Traverse::Filesystem->new(
      ratio => 'compress', bgcolor => 'beige'
  );
  $g->traverse($root);
  print $g->as_debug;

=head1 DESCRIPTION

A C<GraphViz::Traverse::Filesystem> object provides methods to traverse a
file system and render it with C<GraphViz>.

Inherit this module to define and use custom B<node_*> and B<edge_*>
methods.  Example:

  package Foo;
  use strict;
  use warnings;
  use base qw( GraphViz::Traverse::Filesystem );
  sub node_style { return 'filled' }
  sub node_peripheries {
    my $self = shift;
    $_ = shift;
    return !-d $_ && -x $_ ? 2 : 1; # Executable? Get a ring.
  }
  sub node_fillcolor {
    my $self = shift;
    $_ = shift;
    return
        -d $_ ? 'snow' :
        /\.pod$/   ? 'cadetblue' :
        /\.pm$/    ? 'cadetblue4' :
        /\.cgi$/   ? 'cadetblue3' :
        /\.pl$/    ? 'cadetblue2' :
        /(?:readme|changes?)/i ? 'goldenrod' :
        /\.txt$/   ? 'gold4' :
        /\.css$/   ? 'plum' :
        /\.html?$/ ? 'plum3' :
        /\.jpe?g$/ ? 'orchid4' :
        /\.gif$/   ? 'orchid3' :
        /\.png$/   ? 'orchid1' :
        /\.t(?:ar\.)?gz$/ ? 'red3' :
        /\.zip$/   ? 'red1' :
        /\.dump$/  ? 'pink' :
        'yellow';
  }
  sub edge_color { return 'gray' }
  # etc.
  1;

=head1 PUBLIC METHODS

=head2 traverse

  $g->traverse($root);

Traverse a file system starting at the given root path and populate
the C<GraphViz> object with file nodes-and path-edges.

=head1 SEE ALSO

L<GraphViz>

L<GraphViz::Traverse>

=head1 COPYRIGHT

Copyright 2006, Gene Boggs, All Rights Reserved

=head1 LICENSE

You may use this module under the license terms of the parent
L<GraphViz> package.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=cut
