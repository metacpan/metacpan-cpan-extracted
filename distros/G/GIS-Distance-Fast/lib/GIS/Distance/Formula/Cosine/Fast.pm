package GIS::Distance::Formula::Cosine::Fast;
$GIS::Distance::Formula::Cosine::Fast::VERSION = '0.08';
=head1 NAME

GIS::Distance::Formula::Cosine::Fast - C implementation of GIS::Distance::Formula::Cosine.

=head1 DESCRIPTION

This module is used by L<GIS::Distance> and has the same API as
L<GIS::Distance::Formula::Cosine>.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use GIS::Distance::Fast;
use Class::Measure::Length qw( length );

use Moo;
use strictures 1;
use namespace::clean;

with 'GIS::Distance::Formula';

sub distance {
    my $self = shift;

    my $c = GIS::Distance::Fast::cosine_distance( @_ );

    return length( $self->kilometer_rho() * $c, 'km' );
}

1;
