use 5.10.0;
use strict;
use warnings;

package Map::Metro::Exceptions;

# ABSTRACT: Exceptions for Map::Metro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Throwable::SugarFactory;

exception IncompleteParse
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Missing either stations, lines or segments. Check the map file [%s] for errors', $self->mapfile;
        },
    )],
    => has => [mapfile => (is => 'ro')];


exception LineidContainsIllegalCharacter
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Line id [%s] contains illegal character [%s]', $self->line_id, $self->illegal_character;
        },
    )],
    => has => [line_id => (is => 'ro')],
    => has => [illegal_character => (is => 'ro')];


exception LineidDoesNotExistInLineList
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Line id [%s] does not exist in line list (maybe check segments?)', $self->line_id;
        },
    )],
    => has => [line_id => (is => 'ro')];


exception StationNameDoesNotExistInStationList
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Station name [%s] does not exist in station list (check segments or arguments)', $self->station_name;
        },
    )],
    => has => [station_name => (is => 'ro')];


exception StationidDoesNotExist
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Station id [%s] does not exist (check arguments)', $self->station_id;
        },
    )],
    => has => [station_id => (is => 'ro')];


exception NoSuchMap
    => ''
    => has => [desc => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            sprintf 'Could not find map with name [%s] (check if it is installed)', $self->mapname;
        },
    )],
    => has => [mapname => (is => 'ro')];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Exceptions - Exceptions for Map::Metro

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
