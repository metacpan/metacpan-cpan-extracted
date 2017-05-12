package GIS::Distance::Formula::Vincenty::Fast;
$GIS::Distance::Formula::Vincenty::Fast::VERSION = '0.08';
=head1 NAME

GIS::Distance::Formula::Vincenty::Fast - C implementation of GIS::Distance::Formula::Vincenty.

=head1 DESCRIPTION

This module is used by L<GIS::Distance> and has the same API as
L<GIS::Distance::Formula::Vincenty>.

=head1 NOTES

The results from Formula::Vincenty versus Formula::Vincenty::Fast are slightly
different.  I'm still not sure why this is, as the C code is nearly identical to
the Perl code.

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

    my $c = GIS::Distance::Fast::vincenty_distance( @_ );

    return length( $c, 'm' );
}

1;
