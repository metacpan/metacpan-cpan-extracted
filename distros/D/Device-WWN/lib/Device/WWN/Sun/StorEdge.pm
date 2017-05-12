package Device::WWN::Sun::StorEdge;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
extends 'Device::WWN::Hitachi::HDS';
use Device::WWN::Carp qw( croak );

our %FAMILY = (
    '01'    => '7700/"Thunder"',
    '02'    => '9900/"Lightning"',
);

has 'family'    => ( is => 'rw', isa => 'Maybe[Str]', lazy_build => 1 );
sub _build_family { return $FAMILY{ shift->family_id } }

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Device::WWN::Sun::StorEdge - Device::WWN subclass for Sun StorEdge series arrays

=head1 DESCRIPTION

This module is a subclass of L<Device::WWN|Device::WWN> which provides
additional information about Sun StorEdge series arrays.

=head1 METHODS

=head2 family

Return the family name of the array (if known).

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-wwn>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Device::WWN|Device::WWN>

L<Device::WWN::Hitachi::HDS|Device::WWN::Hitachi::HDS>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

