use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Connection;

# ABSTRACT: Connects two stations on a line
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/Maybe Int/;
use Map::Metro::Types qw/LineStation Connection/;
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
has previous_connection => (
    is => 'rw',
    isa => Maybe[ Connection ],
    predicate => 1,
);
has next_connection => (
    is => 'rw',
    isa => Maybe[ Connection ],
    predicate => 1,
);
has weight => (
    is => 'ro',
    isa => Int,
    required => 1,
    default => 1,
);

sub to_hash {
    my $self = shift;

    return {
              origin_line_station => $self->origin_line_station->to_hash,
              destination_line_station => $self->destination_line_station->to_hash,
        maybe previous_connection => $self->has_previous_connection ? $self->previous_connection->to_hash : undef,
        maybe next_connection => $self->has_next_connection ? $self->next_connection->to_hash : undef,
              weight => $self->weight,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Connection - Connects two stations on a line

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 DESCRIPTION

Connections represent the combination of two specific L<LineStations|Map::Metro::Graph::LineStation>, and the 'cost' of
travelling between them.

In L<Graph> terms, a connection is a weighted edge.

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
