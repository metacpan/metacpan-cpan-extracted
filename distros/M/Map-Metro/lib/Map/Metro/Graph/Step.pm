use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Step;

# ABSTRACT: The movement from one station to the next in a route
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/Maybe Int/;
use Map::Metro::Types qw/LineStation Step/;
use PerlX::Maybe qw/maybe/;

has origin_line_station => (
    is => 'ro',
    isa => LineStation,
    required => 1,
);
has destination_line_station => (
    is => 'ro',
    isa => LineStation,
    required => 1,
);
has previous_step => (
    is => 'rw',
    isa => Maybe[ Step ],
    predicate => 1,
);
has next_step => (
    is => 'rw',
    isa => Maybe[ Step ],
    predicate => 1,
);
has weight => (
    is => 'ro',
    isa => Int,
    required => 1,
    default => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    return $class->$orig(%args) if !exists $args{'from_connection'};

    my $conn = $args{'from_connection'};
    return if !defined $conn;

    return $class->$orig(
        origin_line_station => $conn->origin_line_station,
        destination_line_station => $conn->destination_line_station,
        weight => $conn->weight,
    );
};

sub is_line_transfer {
    my $self = shift;

    return $self->origin_line_station->station->id == $self->destination_line_station->station->id;
    return $self->origin_line_station->line->id ne $self->destination_line_station->line->id;
}
sub is_station_transfer {
    my $self = shift;

    my $origin_station_line_ids = [ map { $_->id } $self->origin_line_station->station->all_lines ];
    my $destination_station_line_ids = [ map { $_->id } $self->destination_line_station->station->all_lines ];

    my $are_on_same_line = List::Compare->new($origin_station_line_ids, $destination_station_line_ids)->get_intersection;

    return !$are_on_same_line;
}
sub was_line_transfer {
    my $self = shift;

    return if !$self->has_previous_step;
    return $self->previous_step->is_line_transfer;
}
sub was_station_transfer {
    my $self = shift;

    return if !$self->has_previous_step;
    return $self->previous_step->is_station_transfer;
}

sub to_hash {
    my $self = shift;

    return {
              origin_line_station => $self->origin_line_station->to_hash,
              destination_line_station => $self->destination_line_station->to_hash,
       # maybe previous_step => $self->has_previous_step ? $self->previous_step->to_hash : undef,
       # maybe next_step => $self->has_next_step ? $self->next_step->to_hash : undef,
              weight => $self->weight,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Step - The movement from one station to the next in a route

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 DESCRIPTION

Steps are exactly like L<Connections::Map::Metro::Graph::Connection>, in that they describe the combination of two
specific L<LineStations|Map::Metro::Graph::LineStation>, and the 'cost' of travelling between them, but with an important
difference: A Step is part of a specific L<Route|Map::Metro::Graph::Route>.

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
