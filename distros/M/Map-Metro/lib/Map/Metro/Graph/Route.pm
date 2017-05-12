use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Route;

# ABSTRACT: A sequence of line stations
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/ArrayRef Str/;
use Map::Metro::Types qw/Step LineStation/;
use List::Util qw/sum/;

has steps => (
    is => 'ro',
    isa => ArrayRef[ Step ],
    traits => ['Array'],
    predicate => 1,
    handles => {
        add_step => 'push',
        step_count => 'count',
        get_step => 'get',
        all_steps => 'elements',
        filter_steps => 'grep',
    }
);
has id => (
    is => 'ro',
    isa => Str,
    init_arg => undef,
    default => sub { join '' => map { ('a'..'z', 2..9)[int rand 33] } (1..8) },
);
has line_stations => (
    is => 'ro',
    isa => ArrayRef[ LineStation ],
    traits => ['Array'],
    handles => {
        add_line_station => 'push',
        all_line_stations => 'elements',
        step => 'get',
        line_station_count => 'count',
    },
);

sub weight {
    my $self = shift;

    return sum map { $_->weight } $self->all_steps;
}

sub transfer_on_final_station {
    my $self = shift;

    return 0 if $self->step_count < 2;
    my $final_step = $self->get_step(-1);

    return $final_step->origin_line_station->station->id == $final_step->destination_line_station->station->id;
}
sub transfer_on_first_station {
    my $self = shift;

    return 0 if $self->step_count < 2;
    my $first_step = $self->get_step(0);

    return $first_step->origin_line_station->station->id == $first_step->destination_line_station->station->id;
}
sub longest_line_name_length {
    my $self = shift;

    return length((sort { length $b->origin_line_station->line->name <=> length $a->origin_line_station->line->name } $self->all_steps)[0]->origin_line_station->line->name);
}

sub to_hash {
    my $self = shift;

    return {
        id => $self->id,
        steps => [
            map { $_->to_hash } $self->all_steps,
        ],
        line_stations => [
            map { $_->to_hash } $self->all_line_stations,
        ],
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Route - A sequence of line stations

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 DESCRIPTION

A route is a specific sequence of L<Steps|Map::Metro::Graph::Step> from one L<LineStation|Map::Metro::Graph::LineStation> to another.

=head1 METHODS

=head2 all_steps()

Returns an array of the L<Steps|Map::Metro::Graph::Step> in the route, in the order they are travelled.

=head2 weight()

Returns an integer representing the total 'cost' of all L<Connections|Map::Metro::Graph::Connection> on this route.

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
