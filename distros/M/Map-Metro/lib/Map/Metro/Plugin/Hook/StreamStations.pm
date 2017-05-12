use 5.10.0;
use strict;
use warnings;

package Map::Metro::Plugin::Hook::StreamStations;

# ABSTRACT: Prints stations as they are parsed
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/ArrayRef/;

has station_names => (
    is => 'rw',
    isa => ArrayRef,
    traits => ['Array'],
    handles => {
        add_station_name => 'push',
        all_station_names => 'elements',
        get_station_name => 'get',
    },
);

sub register {
    before_add_station => sub {
        my $self = shift;
        my $station = shift;

        say $station->name;
        $self->add_station_name($station->name);
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Hook::StreamStations - Prints stations as they are parsed

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
