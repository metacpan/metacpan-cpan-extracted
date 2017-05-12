use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Segment;

# ABSTRACT: All lines between two neighboring stations
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/ArrayRef Str Bool/;
use Map::Metro::Types qw/Station/;

has line_ids => (
    is => 'ro',
    isa => ArrayRef[Str],
    traits => ['Array'],
    required => 1,
    default => sub { [] },
    handles => {
        all_line_ids => 'elements',
    }
);
has origin_station => (
    is => 'ro',
    isa => Station,
    required => 1,
);
has destination_station => (
    is => 'ro',
    isa => Station,
    required => 1,
);
has is_one_way => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

sub to_hash {
    my $self = shift;

    return {
        line_ids => [ $self->all_line_ids ],
        origin_station => $self->origin_station->to_hash,
        destination_station => $self->destination_station->to_hash,
        is_one_way => $self->is_one_way,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Segment - All lines between two neighboring stations

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 DESCRIPTION

Segments are used during the graph building phase. Its purpose is to describe the combination of two L<Stations|Map::Metro::Graph::Station>
and all L<Lines|Map::Metro::Graph::Line> that go between them.

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
