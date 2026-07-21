package Map::Tube::Plugin::Graph;

use version;

our $VERSION   = qv('v1.1.0');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Plugin::Graph - Graph plugin for Map::Tube.

=head1 VERSION

Version v1.1.0

=cut

use 5.014;
use Map::Tube::Plugin::Graph::Utils qw(graph_line_image graph_map_image get_graphviz_supported);
use MIME::Base64;
use Graph;

use Moo::Role;
use namespace::autoclean;

=head1 DESCRIPTION

This is a graph plugin for L<Map::Tube> to create maps of individual tube lines
or of a complete tube network. This module is defined as a Moo Role. Once
installed, it gets plugged into the Map::Tube::* family.

=head1 SYNOPSIS

    use strict; use warnings;
    use MIME::Base64;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new;

    # Entire map image to STDOUT
    binmode(STDOUT);
    print STDOUT $tube->as_png();

    # Entire binary map image
    my (undef, $name_bin) = $tube->render( output_file => undef );
    # print "Image written to $name_bin";

    # Entire base64-encoded map image
    my ($base64_string, $name_txt) = $tube->render( output_file => undef, base64 => 1 );

    # Just a particular line map image in binary format
    my (undef, $name_lin) = $tube->render( 'Bakerloo', output_file => undef );
    # print "Image written to $name_lin";

=head1 INSTALLATION

The plugin primarily depends on the GraphViz2 library, which provides an
interface to the external GraphViz tool. GraphViz2 as of 2.61 can only be
installed on Perl v5.008008 or above.

For example, on my Windows 11 box running WSL2 (Ubuntu 24.04 LTS), try this:

    $ sudo apt install libgraphviz2-perl

=head1 METHODS

=head2 as_graph

Returns a C<multiedged>, directed L<Graph> object with the entire map.
You can do graph-theory stuff with it yourself, or even control a
visualisation using the L<GraphViz2/from_graph> API:

  use Map::Tube::London;
  # a convention with GraphViz2 is to have a separate decorating function:
  sub graphvizify {
    my ($g) = @_;
    my $l2c = $g->get_graph_attribute('line2colour');
    for my $ft ($g->edges) {
      $g->set_edge_attribute_by_id(@$ft, $_, graphviz=>{color=>$l2c->{$_}})
        for $g->get_multiedge_ids(@$ft);
    }
  }
  $tube = Map::Tube::London->new;
  $g = $tube->as_graph->undirected_copy_attributes; # make undirected version
  graphvizify($g);
  binmode STDOUT;
  print +GraphViz2->from_graph($g)
    ->run(format=>"png",driver=>"neato") # neato, because dot is bad undirected
    ->dot_output;

Or you can show only two lines using L<Graph/filter_edges>:

  # uses same graphvizify as above
  $g = $tube->as_graph->undirected_copy_attributes; # make undirected version
  my %keep = map +($_=>1), qw(Central Northern);
  $g->filter_edges(sub { $keep{$_[3]} });
  $g->filter_vertices(sub { !$_[0]->is_isolated_vertex($_[1]) });
  graphvizify($g);
  # binmode and print as above

=cut

sub as_graph {
  my ($self) = @_;
  my $g = Graph->new(multiedged=>1);
  my (%station2line, %station2station, %line_name2id);
  for my $line (@{ $self->lines }) {
    $line_name2id{$line->name} = $line->id;
  }
  for my $station (@{ $self->get_stations }) {
    my $from = $station->id;
    @{ $station2line{$from} }{ map $_->name, @{$station->line} } = ();
    @{ $station2station{$from} }{
      map $self->get_node_by_id($_)->id, split /\,/,$station->link
    } = ();
    $g->add_vertex($from);
    $g->set_vertex_attribute( $from, graphviz => { label => $station->name } );
  }
  for my $from (keys %station2station) {
    my @tos = keys %{$station2station{$from}};
    for my $line (keys %{ $station2line{$from} }) {
      my $line_id = $line_name2id{$line};
      for my $to_on_line (
        grep {
          exists $station2line{$_}{$line}
            && !_line_restricted_out($self, $from, $_, $line_id)
        } @tos
      ) {
        # gives false positive for Northern between Waterloo and Bank
        $g->add_edge_by_id($from, $to_on_line, $line);
        delete $station2station{$from}{$to_on_line};
      }
    }
  }
  delete $station2station{$_}
    for grep !keys %{$station2station{$_}}, keys %station2station;
  for my $f (sort keys %station2station) {
    warn qq{Map has link from "$f" to "$_" but no lines in common\n}
      for sort keys %{$station2station{$f}};
  }
  $g->set_graph_attribute(line2colour=>+{
    map +($_->name=>$_->color), @{$self->lines}
  });
  $g;
}

# Returns true if the map's data says the link from $from to $to is
# restricted to a subset of lines that does NOT include $line_id -- i.e.
# the physical link exists, but this particular line doesn't run on it in
# this direction, even though both stations otherwise share the line.
# See Map::Tube's "A:x" style link syntax.
sub _line_restricted_out {
  my ($self, $from, $to, $line_id) = @_;
  return 0 unless defined $line_id;
  my $restrictions = $self->{_link_lines};
  return 0 unless ref $restrictions eq 'HASH';
  my $from_restrictions = $restrictions->{uc($from)};
  return 0 unless defined $from_restrictions;
  my $allowed = $from_restrictions->{uc($to)};
  return 0 unless defined $allowed;
  return !(grep { uc($_) eq uc($line_id) } @$allowed);
}

=head2 render([ $line_name] [, more_parameters...] )

All parameters are optional. If the C<$line_name> is passed in, the method returns
a map for the given line. Otherwise you get the entire tube map.

There are a number of parameters that influence the rendering process and the result:

=over 4

=item * C<format =E<gt> ...>

By default, output is in the PNG bitmap format.  This can be changed by passing
the C<format=> parameter. GraphViz supports many output formats, among them SVG
and PDF and the native GraphViz DOT (or GV) format. While DOT and GV are formally
identical, there is an important difference: GV yields the raw, un-layouted graph
description, whereas DOT yields a graph description where each element is already
precisely placed. -- For a list of supported formats, see the L<list_formats()> method.

=item * C<driver =E<gt> ...>

GraphViz also supports a number of layout engines, or drivers, which can be
customised through the C<driver=> parameter. Usually, the C<dot> driver (which
is the default) or the C<neato> driver will produce good results. -- For a
list of supported drivers, see the L<list_drivers()> method.

=item * C<output_file =E<gt> ...>

If the C<output_file> parameter passes in the name of a file, output will be
written to a file of this name. If its value is C<undef>, a name is
automatically chosen, based on the name of the map or the chosen line. If the
parameter is missing, no output will be written. In this case, the calling
software is responsible for further processing of the output. In particular,
when writing binary output, care must be taken to open the output file in
binary mode on systems (like Windows) that differentiate between text and binary
files.

=item * C<base64 =E<gt> 0|1>

Most of the output formats will produce a binary stream. If the output is meant
to be embedded in a text file (like a web page source), it is useful to
transform it into a purely textual representation. This can be achieved by
passing C<base64 =E<gt> 1>.

=item * C<line_name =E<gt> ...>

The name of the tube line (if any) may be given as the first parameter, as shown
above, but also, alternatively, as a named parameter C<line_name=>. If both are
given, the value of the first parameter will take precedence.

=back

In scalar context, the method will return the representation of the graph
in the desired format (which may be binary). In array context, the method will
return an array of two elements: first the repesentation of the graph, then the
name of the output file (or undef if no file output was requested).

See L</SYNOPSIS> for more details on how this method can be used.

=cut

sub render {
  my ($self, @args) = @_;
  my $line_name = ( scalar(@args) & 1 ) ? shift(@args) : undef;
  my %args = @args;
  $line_name //= $args{line_name} if exists $args{line_name};
  delete $args{line_name};
  my $base64 = $args{base64};
  delete $args{base64};
  my @result = defined $line_name ? graph_line_image($self, $line_name, %args)
                                  : graph_map_image($self, %args);
  $result[0] = encode_base64($result[0]) if $base64 && @result;
  return wantarray ? @result : $result[0];
}

=head2 as_png($line_name [, ...])

The C<$line_name> parameter is optional. If it is passed, the method returns the
given line map as a PNG bitmap. Otherwise you get the entire map.

(In fact, this method is almost an alias for the L<render()> method. However, it always
returns only the graph representation, never an output file name.)

See "SYNOPSIS" for more details on how it can be used.

=cut

sub as_png {
  my ($self, @args) = @_;
  return scalar($self->render(@args));
}

=head2 as_image($line_name, [, ...])

The C<$line_name> parameter is optional. If it is passed, the method returns the
base64 encoded string of a PNG bitmap showing the given line map. Otherwise you
get the entire map as a base64 encoded string.

(In fact, this method is almost an alias for the L<render()> method. One
difference is that the C<base64=> parameter is set to TRUE. And it always
returns only the graph representation, never an output file name.)

See L</SYNOPSIS> for more details on how it can be used.

=cut

sub as_image {
  my ($self, @args) = @_;
  push( @args, base64 => 1 );
  return scalar($self->render(@args));
}

=head2 list_drivers()

Returns a list of drivers (formatters) that GraphViz supports on your machine.
The basic C<dot> driver must be available via the search path for executables.

=cut

sub list_drivers {
  return get_graphviz_supported('-K?');
}

=head2 list_formats()

Returns a list of output formats that GraphViz supports on your machine.

=cut

sub list_formats {
  return get_graphviz_supported('-T?');
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Plugin-Graph>

=head1 SEE ALSO

=over 4

=item * L<Map::Tube::GraphViz>

=item * L<Map::Metro::Graph>

=back

=head1 CONTRIBUTORS

=over 2

=item * Gisbert W. Selke

=item * Ed J

=back

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube-Plugin-Graph/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Plugin::Graph

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube-Plugin-Graph/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube-Plugin-Graph>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and / or modify it under
the terms of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make, have made, use, offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are necessarily infringed by the Package. If you institute patent litigation
(including a cross-claim or counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Map::Tube::Plugin::Graph
