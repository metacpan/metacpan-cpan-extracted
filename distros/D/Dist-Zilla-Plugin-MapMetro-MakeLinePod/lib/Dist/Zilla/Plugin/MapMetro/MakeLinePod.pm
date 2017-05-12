use 5.10.1;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::MapMetro::MakeLinePod;

our $VERSION = '0.1202'; # VERSION
# ABSTRACT: Automatically include line and station info in Map::Metro map

use Moose;
use namespace::autoclean;
use Path::Tiny;
use List::AllUtils qw/any all uniq/;
use Types::Standard qw/Str Maybe/;
use Map::Metro::Shim;
use syntax 'qi';

use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';

has cityname => (
    is => 'rw',
    isa => Maybe[Str],
    predicate => 1,
);

sub gather_files {
    my $self = shift;
    my $arg = shift;

    return if $ENV{'MMNOLINES'};
    $self->log('Set MMNOLINES=1 to skip building Lines.pod');

    my @cities = path(qw/lib Map Metro Plugin Map/)->children(qr/\.pm/);
    return if !scalar @cities;

    my @mapfiles = path('share')->children(qr{map-.*\.metro});
    return if !scalar @mapfiles;

    my $city = (shift @cities)->basename;
    $city =~ s{\.pm}{};
    my $mapfile = shift @mapfiles;

    my $graph = Map::Metro::Shim->new(filepath => $mapfile)->parse(override_line_change_weight => 99999999);

    my @linepod = ();

    LINE:
    foreach my $line ($graph->all_lines) {

        my $css_line_id = $line->description;
        $css_line_id =~ s{ }{-}g;
        $css_line_id =~ s{[^a-z0-9_-]}{}ig;

        my @stations = $graph->filter_stations(sub {
            my $station = $_;
            return any { $_->id eq $line->id } $station->all_lines;
        });
        $self->log(sprintf 'Line %s, found %s stations', $line->name, scalar @stations);

        my @routes;
        ORIGIN:
        foreach my $i (0 .. $#stations) {
            my $origin_station = $stations[ $i ];


            DESTINATION:
            foreach my $j (0 .. $#stations) {
                my $destination_station = $stations[ $j ];
                next DESTINATION if $origin_station->id == $destination_station->id;

                my $route = $graph->routing_for($origin_station->id, $destination_station->id)->get_route(0);
                push @routes => $route if defined $route;
            }
        }

        # Find the two longest routes (termini<->termini, and then pick the alphabetical order)
        my $chosen_route =  (sort { $a->get_step(0)->origin_line_station->station->name cmp $b->get_step(0)->origin_line_station->station->name }
                               (sort { $b->step_count <=> $a->step_count } @routes)[0, 1]
                            )[0];

        my $longest_station_name_length = length ((sort { length $b->name <=> length $a->name } @stations)[0]->name);

        my @station_pod;
        foreach my $step ($chosen_route->all_steps) {
            my @change_to_strings = $self->make_change_to_string($graph, $step->origin_line_station);
            if(scalar @change_to_strings) {
                unshift @change_to_strings => ' ' x ($longest_station_name_length - length $step->origin_line_station->station->name);
            }
            push @station_pod => (' ' x 5) . join ' ' => $step->origin_line_station->station->name, @change_to_strings;

            if(!$step->has_next_step) {
                @change_to_strings = $self->make_change_to_string($graph, $step->destination_line_station);
                if(scalar @change_to_strings) {
                    unshift @change_to_strings => ' ' x ($longest_station_name_length - length $step->destination_line_station->station->name);
                }

                push @station_pod => (' ' x 5) .  join ' ' => $step->destination_line_station->station->name, @change_to_strings;
            }
        }

        push @linepod => sprintf '=head2 %s: %s → %s [%s]' => $line->description,
                                                              $chosen_route->get_step(0)->origin_line_station->station->name,
                                                              $chosen_route->get_step(-1)->destination_line_station->station->name,
                                                              $line->name;
        my $css_color = $line->color;
        push @linepod => qq{
            =for HTML <div style="background-color: $css_color; margin-top: -23px; margin-left: 10px; height: 3px; width: 98%%;"></div>
        };

        push @linepod => '', @station_pod, '';

    }

    my $file = Dist::Zilla::File::InMemory->new(
        name => "lib/Map/Metro/Plugin/Map/$city/Lines.pod",
        content => $self->make_line_contents($city, @linepod),
    );
    $self->add_file($file);

    return;
}

sub make_change_to_string {
    my $self = shift;
    my $graph = shift;
    my $line_station = shift;

    my @change_strings = ();
    my @other_lines = map { $_->name } $line_station->station->filter_lines(sub { $_->id ne $line_station->line->id });
    @other_lines = (all { $_ =~ /^\d+$/ } @other_lines) ? sort { $a <=> $b } @other_lines
                 :                                        sort { $a cmp $b } @other_lines
                 ;

    push @change_strings => scalar @other_lines ? sprintf '(%s)', join ', ' => @other_lines
                         :                       ()
                         ;

    my @transfers = $graph->filter_transfers(sub { $_->origin_station->id == $line_station->station->id });
    push @change_strings => scalar @transfers ? join ' ' => map {
                                                                sprintf ('[%s: %s]', $_->destination_station->name,
                                                                join ', ' => map { $_->name } $_->destination_station->all_lines )
                                                            } @transfers
                         :                      ()
                         ;

    @transfers = $graph->filter_transfers(sub { $_->destination_station->id == $line_station->station->id });
    push @change_strings => scalar @transfers ? join ' ' => map {
                                                                sprintf ('[%s: %s]', $_->origin_station->name,
                                                                join ', ' => map { $_->name } $_->origin_station->all_lines )
                                                            } @transfers
                         :                      ()
                         ;

    return @change_strings;
}

sub make_line_contents {
    my $self = shift;
    my $city = shift;
    my $content = join "\n" => @_;

    $content = sprintf qqi{
 # %s: Map::Metro::Plugin::Map::${city}::Lines
 # %s: Lines and stations in the $city map

 =pod

 =encoding utf-8

 =head1 LINES

 $content

 =head1 SEE ALSO

 =for :list
 * L<Map::Metro::Plugin::Map::$city>
 * L<Task::MapMetro::Maps>
 * L<Map::Metro>

 =cut
}, 'PODNAME', 'ABSTRACT';

    $content =~ s{\s+=(begin|end|for)}{\n\n=$1}g;

    return $content;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MakeLinePod - Automatically include line and station info in Map::Metro map



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.14+-brightgreen.svg" alt="Requires Perl 5.14+" /> <a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-MapMetro-MakeLinePod"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-MapMetro-MakeLinePod.svg?branch=master" alt="Travis status" /></a></p>

=end HTML


=begin markdown

![Requires Perl 5.14+](https://img.shields.io/badge/perl-5.14+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-MapMetro-MakeLinePod.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-MapMetro-MakeLinePod)

=end markdown

=head1 VERSION

Version 0.1202, released 2015-11-02.

=head1 SYNOPSIS

  ; in dist.ini
  [MapMetro::MakeLinePod]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin creates a C<::Lines> pod detailing all lines, stations, changes and transfers in the map.

=head1 SEE ALSO

=over 4

=item *

L<Task::MapMetro::Dev> - Map::Metro development tools

=item *

L<Map::Metro::Plugin::Map::Barcelona::Lines> - An example

=item *

L<Map::Metro>

=item *

L<Map::Metro::Plugin::Map>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-MapMetro-MakeLinePod>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-MapMetro-MakeLinePod>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
