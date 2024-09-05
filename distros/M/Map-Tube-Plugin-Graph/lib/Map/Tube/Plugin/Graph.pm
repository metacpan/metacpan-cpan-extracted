package Map::Tube::Plugin::Graph;

$Map::Tube::Plugin::Graph::VERSION   = '0.45';
$Map::Tube::Plugin::Graph::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Plugin::Graph - Graph plugin for Map::Tube.

=head1 VERSION

Version 0.45

=cut

use 5.006;
use Data::Dumper;
use Map::Tube::Plugin::Graph::Utils qw(graph_line_image graph_map_image);
use MIME::Base64;
use Graph;

use Moo::Role;
use namespace::autoclean;

=head1 DESCRIPTION

It's a graph plugin for L<Map::Tube> to create map of individual lines defined as
Moo Role. Once installed, it gets plugged into Map::Tube::* family.

=head1 SYNOPSIS

    use strict; use warnings;
    use MIME::Base64;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new;

    # Entire map image to STDOUT
    binmode(STDOUT);
    print STDOUT $tube->as_png;

    # Entire map image
    my $name = $tube->name;
    open(my $MAP_IMAGE, ">", "$name.png")
        or die "ERROR: Can't open [$name.png]: $!";
    binmode($MAP_IMAGE);
    print $MAP_IMAGE decode_base64($tube->as_image);
    close($MAP_IMAGE);

    # Just a particular line map image
    my $line = 'Bakerloo';
    open(my $LINE_IMAGE, ">", "$line.png")
        or die "ERROR: Can't open [$line.png]: $!";
    binmode($LINE_IMAGE);
    print $LINE_IMAGE decode_base64($tube->as_image($line));
    close($LINE_IMAGE);

=head1 INSTALLATION

The plugin primarily depends on GraphViz2 library. But GraphViz2 as of 2.61 can
only be installed on perl v5.008008 or above.

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
  my (%station2line, %station2station);
  for my $station (@{ $self->get_stations }) {
    my $from = $station->name;
    @{ $station2line{$from} }{ map $_->name, @{$station->line} } = ();
    @{ $station2station{$from} }{
      map $self->get_node_by_id($_)->name, split /\,/,$station->link
    } = ();
  }
  for my $from (keys %station2station) {
    my @tos = keys %{$station2station{$from}};
    for my $line (keys %{ $station2line{$from} }) {
      for my $to_on_line (grep exists $station2line{$_}{$line}, @tos) {
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

=head2 as_png($line_name)

The C<$line_name> param is optional. If it's passed, the method returns
the given line map. Otherwise you get the entire map.

See L</SYNOPSIS> for more details on how it can be used.

=cut

sub as_png {
  my ($self, $line_name) = @_;
  defined $line_name
    ? graph_line_image($self, $line_name)
    : graph_map_image($self);
}

=head2 as_image($line_name)

The C<$line_name> param is optional. If it's passed, the method returns the base64
encoded string of the given line map. Otherwise you would get the entire map as
base64 encoded string.

See L</SYNOPSIS> for more details on how it can be used.

=cut

sub as_image {
  my ($self, $line_name) = @_;
  encode_base64($self->as_png($line_name));
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

Copyright (C) 2015 - 2024 Mohammad Sajid Anwar.

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
