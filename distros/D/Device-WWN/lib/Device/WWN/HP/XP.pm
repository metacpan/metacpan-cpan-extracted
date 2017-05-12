package Device::WWN::HP::XP;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
extends 'Device::WWN::Hitachi::HDS';
use Device::WWN::Carp qw( croak );

our %FAMILY = (
    '01'        => 'XP256',
    '02'        => 'XP512/XP48',
    '03'        => 'XP1024/XP128',
    '04'        => 'XP12000/XP10000',
    '05'        => 'XP24000/XP20000',
);

has 'family'    => ( is => 'rw', isa => 'Maybe[Str]', lazy_build => 1 );
sub _build_family { return $FAMILY{ shift->family_id } }

# example:
# HP XP Port WWN = 50:00:60:E8:01:12:34:0A
# 12:34 - Serial#
# 0A - CHIP Port
# 0 - means 1
# A - means L (see table)
#
# Description:  XP 12000, disk system 5004, FRHA043981
# WWN:          50:06:0e:80:04:ab:cd:00
# Serial:       hex: abcd dec: 43981
# Model:        04 => XP12000
# CHIP:         1A

# Description:  XP 12000, disk system 5005, FRHA012345
# WWN:          50:06:0e:80:04:30:39:04
# Serial:       hex: 3039 dec: 12345
# Model:        04 => XP12000
# CHIP:         1D

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Device::WWN::HP::XP - Device::WWN subclass for HP XP series arrays

=head1 DESCRIPTION

This module is a subclass of L<Device::WWN|Device::WWN> which provides
additional information about HP XP series arrays.

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

