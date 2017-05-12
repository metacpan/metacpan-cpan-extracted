use 5.10.0;
use strict;
use warnings;

package Map::Metro::Plugin::Hook::Helsinki::Swedish;

# ABSTRACT: Use the Swedish station names
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1987';

use Moose;
use namespace::autoclean;
use Map::Metro::Hook;
use Encode qw/encode_utf8 decode_utf8/;
use utf8;

sub register {
    before_add_station => sub {

        my $self = shift;
        my $station = shift;
        $station->set_name($self->station_translation($station->name));

    };
}

sub station_translation {
    my $self = shift;
    my $name = shift;

    my $to_swedish = {
        'Ruoholahti' => 'Gräsviken',
        'Kamppi' => 'Kampen',
        'Rautatientori' => 'Järnvägstorget',
        'Kaisaniemi' => 'Kajsaniemi',
        'Hakaniemi' => 'Hagnäs',
        'Sörnälnen' => 'Sörnäs',
        'Kalasatama' => 'Fiskhamnen',
        'Kulosaari' => 'Brändö',
        'Herttoniemi' => 'Hertonäs',
        'Siilitie' => 'Igelkottsvägen',
        'Itäkeskus' => 'Östra centrum',
        'Myllypuro' => 'Kvarnbäcken',
        'Kontula' => 'Gårdsbacka',
        'Mellunmäki' => 'Mellungsbacka',
        'Puotila' => 'Botby gård',
        'Rastila' => 'Rastböle',
        'Vuosaari' => 'Nordsjö',
    };
    return $to_swedish->{ $name } // $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Hook::Helsinki::Swedish - Use the Swedish station names

=head1 VERSION

Version 0.1987, released 2016-10-30.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Helsinki>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Helsinki>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
