use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd::Graphviz;

# ABSTRACT: Make a visualization using GraphViz2
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use MooseX::App::Command;
extends 'Map::Metro::Cmd';
use Path::Tiny;
use Types::Standard qw/Str HashRef/;
use Module::Load qw/load/;
use Try::Tiny;

parameter cityname => (
    is => 'rw',
    isa => Str,
    documentation => 'The name of the map',
    required => 1,
);
parameter customlens => (
    is => 'rw',
    isa => Str,
    documentation => 'Custom distances between stations (origin_station_id->destination_station_id:len)',
);
option into => (
    is => 'rw',
    isa => Str,
);
has lens => (
    is => 'rw',
    isa => HashRef,
    traits => ['Hash'],
    handles => {
        set_len => 'set',
        get_len => 'get',
    },
);

command_short_description 'Make a visualization using GraphViz2';

sub run {
    my $self = shift;

    try {
        load "GraphViz2";
    }
    catch {
        die $_;
    };

    my %hooks = (hooks => ['PrettyPrinter']);
    my $graph = $self->cityname !~ m{\.} ? Map::Metro->new($self->cityname, %hooks)->parse : Map::Metro::Shim->new($self->cityname, %hooks)->parse;

    my $customconnections = { };
    if($self->customlens) {
        my $customlens = path($self->customlens)->exists ? do {
                                                               my $settings = path($self->customlens)->slurp;
                                                               $settings =~  s{^#.*$}{}g;
                                                               $settings =~ s{\n}{ }g;
                                                               $settings;
                                                           }
                       :                                   $self->customlens
                       ;

        foreach my $custom (split m/ +/ => $customlens) {
            if($custom =~ m{^(\d+)->(\d+):([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $len = $3;

                $self->set_len(sprintf ('%s-%s', $origin_station_id, $destination_station_id), $len);
                $self->set_len(sprintf ('%s-%s', $destination_station_id, $origin_station_id), $len);
            }
            elsif($custom =~ m{^!(\d+)->(\d+):([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $len = $3;

                $customconnections->{ $origin_station_id }{ $destination_station_id } = $len;
            }
        }
    }

    my $viz = GraphViz2->new(
        global => { directed => 0 },
        graph => { epsilon => 0.00001 },
        node => { shape => 'circle', fixedsize => 'true', width => 0.8, height => 0.8, penwidth => 3, fontname => 'sans-serif', fontsize => 20 },
        edge => { penwidth => 5, len => 1.2 },
    );
    foreach my $station ($graph->all_stations) {
        $viz->add_node(name => $station->id, label => $station->id);
    }

    foreach my $transfer ($graph->all_transfers) {
        my %len = $self->get_len_for($transfer->origin_station->id, $transfer->destination_station->id);
        $viz->add_edge(from => $transfer->origin_station->id, to => $transfer->destination_station->id, color => '#888888', style => 'dashed', %len);
    }
    foreach my $segment ($graph->all_segments) {
        foreach my $line_id ($segment->all_line_ids) {
            my $color = $graph->get_line_by_id($line_id)->color;
            my $width = $graph->get_line_by_id($line_id)->width;
            my %len = $self->get_len_for($segment->origin_station->id, $segment->destination_station->id);

            $viz->add_edge(from => $segment->origin_station->id,
                           to => $segment->destination_station->id,
                           color => $color,
                           penwidth => $width,
                           %len,
            );
        }
    }
    #* Custom connections (for better visuals)
    foreach my $origin_station_id (keys %{ $customconnections }) {
        foreach my $destination_station_id (keys %{ $customconnections->{ $origin_station_id }}) {
            my $len = $customconnections->{ $origin_station_id }{ $destination_station_id };
            $viz->add_edge(from => $origin_station_id,
                           to => $destination_station_id,
                           color => '#ffffff',
                           penwidth => 0,
                           len => $len,
            );
        }
    }

    my $output = $self->into // sprintf 'viz-%s-%s.png', $self->cityname, time;
    $viz->run(format => 'png', output_file => $output, driver => 'neato');

    say sprintf 'Saved in %s.', $output;
}

sub get_len_for {
    my $self = shift;
    my $origin_station_id = shift;
    my $destination_station_id = shift;

    return (len => $self->get_len("$origin_station_id-$destination_station_id")) if $self->get_len("$origin_station_id-$destination_station_id");
    return (len => $self->get_len("$origin_station_id-0")) if $self->get_len("$origin_station_id-0");
    return (len => $self->get_len("0-$destination_station_id")) if $self->get_len("0-$destination_station_id");
    return ();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::Graphviz - Make a visualization using GraphViz2

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
