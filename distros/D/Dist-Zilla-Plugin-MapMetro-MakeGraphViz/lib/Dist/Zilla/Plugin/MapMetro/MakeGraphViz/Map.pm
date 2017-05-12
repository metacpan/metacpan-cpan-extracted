use 5.14.0;
use warnings;

package Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map;

our $VERSION = '0.1104';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use MooseX::AttributeShortcuts;
use Types::Standard qw/HashRef ArrayRef Str Maybe/;
use Types::Path::Tiny qw/Path/;
use Map::Metro::Shim;
use String::CamelCase qw/decamelize/;
use GraphViz2;

has map => (
    is => 'rw',
    isa => Str,
    required => 1,
);

has settings => (
    is => 'rw',
    isa => HashRef,
    traits => ['Hash'],
    init_arg => undef,
    default => sub { { } },
    handles => {
        set_setting => 'set',
        get_setting => 'get',
    },
);
has hidden_positions => (
    is => 'rw',
    isa => ArrayRef,
    traits => ['Array'],
    init_arg => undef,
    default => sub { [] },
    handles => {
        add_hidden => 'push',
        all_hiddens => 'elements',
    },
);
has generated_file => (
    is => 'rw',
    isa => Path,
    predicate => 1,
    init_arg => undef,
);

sub BUILD {
    my $self = shift;

    my $decamelized_map = decamelize($self->map);

    my @possible_graphvizfiles = (
        path('share', 'graphviz.conf'),
        path('share', $decamelized_map, "graphviz-$decamelized_map.conf")
    );
    my $graphvizfile = (grep { $_->exists } @possible_graphvizfiles)[0];

    my @possible_mapfiles = (
        path('share', "map-$decamelized_map.metro"),
        path('share', $decamelized_map, "map-$decamelized_map.metro")
    );
    my $mapfile = (grep { $_->exists } @possible_mapfiles)[0];
    return if !defined $mapfile;

    my $graph = Map::Metro::Shim->new(filepath => $mapfile)->parse;

    my $customconnections = {};
    if($graphvizfile) {
        my $settings = $graphvizfile->slurp;
        $settings =~  s{^#.*$}{}g;
        $settings =~ s{\n}{ }g;

        for my $custom (split m/ +/ => $settings) {
            if($custom =~ m{^(\d+)-(\d+):([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $len = $3;

                $self->set_setting(sprintf ('len-%s-%s', $origin_station_id, $destination_station_id), $len);
                $self->set_setting(sprintf ('len-%s-%s', $destination_station_id, $origin_station_id), $len);
            }
            elsif($custom =~ m{^\*(\d+):(-?[\d\.]+,-?[\d\.]+)}) {
                my $station_id = $1;
                my $hidden_station_pos = $2;

                $self->add_hidden({ station_id => $station_id, pos => $hidden_station_pos });
            }
            elsif($custom =~ m{^(\d+):(-?\d+,-?\d+!?)$}) {
                my $station_id = $1;
                my $pos = $2;

                $self->set_setting(sprintf ('pos-%s', $station_id) => $pos);
            }
            elsif($custom =~ m{^!(\d+)-(\d+):(\d+)\^([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $connections = $3;
                my $len = $4;

                $customconnections->{ $origin_station_id }{ $destination_station_id } = { connections => $connections, len => $len };
            }
        }
    }

    my $viz = GraphViz2->new(
        global => { directed => 0 },
        graph => { epsilon => 0.00001, fontname => 'sans-serif', fontsize => 100, label => $self->map, labelloc => 'top' },
        node => { shape => 'circle', fixedsize => 'true', width => 0.8, height => 0.8, penwidth => 3, fontname => 'sans-serif', fontsize => 20 },
        edge => { penwidth => 5, len => 1.2 },
    );
    for my $station ($graph->all_stations) {
        my %pos = $self->get_pos_for($station->id);
        my %node = (name => $station->id, label => $station->id, %pos);
        $viz->add_node(%node);
    }

    for my $transfer ($graph->all_transfers) {
        my %len = $self->get_len_for($transfer->origin_station->id, $transfer->destination_station->id);
        $viz->add_edge(from => $transfer->origin_station->id, to => $transfer->destination_station->id, color => '#888888', style => 'dashed', %len);
    }
    for my $segment ($graph->all_segments) {
        for my $line_id ($segment->all_line_ids) {
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
    my $invisible_station_id = 99000000;
    for my $hidden ($self->all_hiddens) {
        $viz->add_node(name => ++$invisible_station_id,
                       label => '',
                       ($ENV{'MMVIZDEBUG'} ? () : (style => 'invis')),
                       width => 0.1,
                       height => 0.1,
                       penwidth => 5,
                       color => '#ff0000',
                       pos => "$hidden->{'pos'}!",
        );
        $viz->add_edge(from => $invisible_station_id,
                       to => $hidden->{'station_id'},
                       color => $ENV{'MMVIZDEBUG'} ? '#ff0000' : '#ffffff',
                       penwidth => 5,
                       len => 1,
                       weight => 100,
        );
    }


    for my $origin_station_id (keys %{ $customconnections }) {
        for my $destination_station_id (keys %{ $customconnections->{ $origin_station_id }}) {
            my $len = $customconnections->{ $origin_station_id }{ $destination_station_id }{'len'};
            my $connection_count = $customconnections->{ $origin_station_id }{ $destination_station_id }{'connections'};

            my $previous_station_id = $origin_station_id;

            for my $extra_connection (1 .. $connection_count - 1) {
                $viz->add_node(name => ++$invisible_station_id, label => '', style => 'invis', width => 0.1, height => 0.1, penwidth => 5, color => '#ff0000');

                $viz->add_edge(from => $previous_station_id,
                               to => $invisible_station_id,
                               color => '#ff0000',
                               penwidth => $ENV{'MMVIZDEBUG'} ? 1 : 0,
                               len => $len,
                );

                $previous_station_id = $invisible_station_id;
            }

            $viz->add_edge(from => $previous_station_id,
                           to => $destination_station_id,
                           color => '#ff0000',
                           penwidth => $ENV{'MMVIZDEBUG'} ? 1 : 0,
                           len => $len,
            );
        }
    }

    my $image_dir = path(qw/static images/);
    $image_dir->mkpath;
    my $file = $image_dir->child(decamelize($self->map) . '.png');
    $viz->run(format => 'png', output_file => $file->stringify, driver => 'neato');
    $self->generated_file($file);
}


sub get_len_for {
    my $self = shift;
    my ($origin_station_id, $destination_station_id) = @_;
    return (len => $self->get_setting("len-$origin_station_id-$destination_station_id")) if $self->get_setting("len-$origin_station_id-$destination_station_id");
    return (len => $self->get_setting("len-$origin_station_id-0")) if $self->get_setting("len-$origin_station_id-0");
    return (len => $self->get_setting("len-0-$destination_station_id")) if $self->get_setting("len-0-$destination_station_id");
    return ();
}

sub get_pos_for {
    my $self = shift;
    my $station_id = shift;
    return (pos => $self->get_setting("pos-$station_id")) if $self->get_setting("pos-$station_id");
    return ();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map

=head1 VERSION

Version 0.1104, released 2016-02-07.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-MapMetro-MakeGraphViz>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
