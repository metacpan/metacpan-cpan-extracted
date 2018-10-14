package Map::Tube::Plugin::Graph::Utils;

$Map::Tube::Plugin::Graph::Utils::VERSION   = '0.36';
$Map::Tube::Plugin::Graph::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Plugin::Graph::Utils - Helper package for Map::Tube::Plugin::Graph.

=head1 VERSION

Version 0.36

=cut

use 5.006;
use strict; use warnings;
use GraphViz2;
use Data::Dumper;
use MIME::Base64;
use Map::Tube::Utils qw(is_valid_color);
use Map::Tube::Exception::MissingLineName;
use Map::Tube::Exception::InvalidLineName;
use Map::Tube::Exception::InvalidColorName;
use Map::Tube::Exception::InvalidColorHexCode;
use File::Temp qw(tempfile tempdir);
use parent 'Exporter';

our @EXPORT_OK = qw(graph_line_image graph_map_image);

our $STYLE      = 'dashed';
our $NODE_COLOR = 'black';
our $EDGE_COLOR = 'brown';
our $SHAPE      = 'oval';
our $DIRECTED   = 1;
our $ARROWSIZE  = 1;
our $LABELLOC   = 'top';
our $BGCOLOR    = 'grey';

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=cut

sub graph_line_image {
    my ($map, $line_name) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingLineName->throw({
        method      => __PACKAGE__."::graph_line_image",
        message     => "ERROR: Missing Line name.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless defined $line_name;

    my $line = $map->_get_line_object_by_name($line_name);
    Map::Tube::Exception::InvalidLineName->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Invalid Line name [$line_name].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless defined $line;

    my $color   = $EDGE_COLOR;
    $color      = $line->color if defined $line->color;
    $line_name  = $line->name;
    my $bgcolor = $map->bgcolor;
    $bgcolor    = _graph_bgcolor($color) unless defined $bgcolor;

    my $graph  = GraphViz2->new(
        edge   => { color     => $color,
                    arrowsize => $ARROWSIZE },
        node   => { shape     => $SHAPE     },
        global => { directed  => $DIRECTED  },
        graph  => { label     => _graph_line_label($line_name, $map->name),
                    labelloc  => $LABELLOC,
                    bgcolor   => $bgcolor });

    my $stations = $line->get_stations;
    foreach my $node (@$stations) {
        $graph->add_node(name      => $node->name,
                         color     => $color,
                         fontcolor => $color);
    }

    my $skip = $map->{skip};
    foreach my $node (@$stations) {
        my $from = $node->name;
        foreach (split /\,/,$node->link) {
            my $to = $map->get_node_by_id($_);
            next if (defined $skip
                     &&
                     (exists $skip->{$line_name}->{$from}->{$to->name}
                      ||
                      exists $skip->{$line_name}->{$to->name}->{$from}));

            if (grep /$line_name/, (map { $_->name } @{$to->line})) {
                $graph->add_edge(from => $from, to => $to->name);
            }
            else {
                $graph->add_edge(from  => $from,
                                 to    => $to->name,
                                 color => $color,
                                 style => $STYLE);
            }
        }
    }

    return _graph_encode_image($graph);
}

sub graph_map_image {
    my ($map) = @_;

    my $bgcolor = $map->bgcolor;
    $bgcolor = $BGCOLOR unless defined $bgcolor;

    my $graph  = GraphViz2->new(
        node   => { shape     => $SHAPE     },
        edge   => { arrowsize => $ARROWSIZE },
        global => { directed  => $DIRECTED  },
        graph  => { label     => _graph_map_label($map->name),
                    labelloc  => $LABELLOC,
                    bgcolor   => $bgcolor
        });

    my $lines    = $map->lines;
    my $stations = [];
    foreach my $line (@$lines) {
        next unless defined ($line->name);

        foreach my $station (@{$map->get_stations($line->name)}) {
            push @$stations, $station;
            my $color  = $NODE_COLOR;
            my $_lines = $station->line;
            $color = $line->color if ((scalar(@$_lines) == 1) && defined $line->color);
            $graph->add_node(name      => $station->name,
                             color     => $color,
                             fontcolor => $color);
        }
    }

    my $seen = {};
    foreach my $station (@$stations) {
        my $from = $station->name;
        foreach (split /\,/,$station->link) {
            my $to = $map->get_node_by_id($_);
            next if $seen->{$from}->{$to->name};
            $graph->add_edge(from => $from, to => $to->name);
            $seen->{$from}->{$to->name} = 1;
        }
    }

    return _graph_encode_image($graph);
}

#
#
# PRIVATE METHODS

sub _graph_encode_image {
    my ($graph) = @_;

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(DIR => $dir);
    $graph->run(format => 'png', output_file => "$filename");
    my $raw_string = do { local $/ = undef; <$fh>; };

    return encode_base64($raw_string);
}

sub _graph_line_label {
    my ($line_name, $map_name) = @_;

    $map_name = '' unless defined $map_name;
    return sprintf("%s Map: %s Line (Generated by Map::Tube::Plugin::Graph v%s at %s)",
                   $map_name, $line_name, $Map::Tube::Plugin::Graph::VERSION, _graph_timestamp());
}

sub _graph_map_label {
    my ($map_name) = @_;

    $map_name = '' unless defined $map_name;
    return sprintf("%s Map (Generated by Map::Tube::Plugin::Graph v%s at %s)",
                   $map_name, $Map::Tube::Plugin::Graph::VERSION, _graph_timestamp());
}

sub _graph_timestamp {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

# TODO: Unfinished work, still not getting the right combination.
sub _graph_bgcolor {
    my ($color) = @_;

    unless ($color =~ /^#(..)(..)(..)$/) {
        my $hexcode = Map::Tube::Utils::is_valid_color($color);
        unless ($hexcode) {
            my @caller = caller(0);
            @caller    = caller(2) if $caller[3] eq '(eval)';

            Map::Tube::Exception::InvalidColorName->throw({
                method      => __PACKAGE__."::_graph_bgcolor",
                message     => "ERROR: Invalid Color Name [$color].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }

        $color = $hexcode;
    }

    return _graph_contrast_color($color);
}

# Code borrowed from http://www.perlmonks.org/?node_id=261561 provided by msemtd.
sub _graph_contrast_color {
    my ($color) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::InvalidColorHexCode->throw({
        method      => __PACKAGE__."::graph_line_image",
        message     => "ERROR: Invalid color hex code.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($color =~ /^#(..)(..)(..)$/);

    my ($r, $g, $b) = (hex($1), hex($2), hex($3));
    my %oppcolors = (
        "00" => "FF",
        "33" => "FF",
        "66" => "FF",
        "99" => "FF",
        "CC" => "00",
        "FF" => "00",
    );

    $r = int($r / 51) * 51;
    $g = int($g / 51) * 51;
    $b = int($b / 51) * 51;

    $r = $oppcolors{sprintf("%02X", $r)};
    $g = $oppcolors{sprintf("%02X", $g)};
    $b = $oppcolors{sprintf("%02X", $b)};

    return "#$r$g$b";
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Plugin-Graph>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Plugin-Graph>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Plugin::Graph::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Plugin-Graph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Plugin-Graph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Plugin-Graph>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Plugin-Graph/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Map::Tube::Plugin::Graph::Utils
