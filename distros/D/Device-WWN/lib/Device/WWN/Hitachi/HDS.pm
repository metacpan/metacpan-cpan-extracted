package Device::WWN::Hitachi::HDS;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
extends 'Device::WWN';
use Device::WWN::Carp qw( croak );

# http://brionetka.com/linux/?p=38
#
sub accept_wwn {
    my ( $self, $wwn ) = @_;
    return $wwn =~ /^50060e8/;
}

has '+wwn' => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %ports = qw(
            A 0 B 1 C 2 D 3 E 4 F 5 G 6 H 7
            J 8 K 9 L A M B N C O D P E Q F
        );
        $self->port =~ /^([01])(\w)$/ or croak "Invalid port";
        my $port = ( $1 - 1 ) . $ports{ $2 };
        my $oui = $self->oui->normalized;
        $oui =~ s/[^a-f0-9]//ig;
        my $fid = sprintf( '%02d', $self->family_id );
        my $serial = sprintf( '%X', $self->serial_number );
        return join( '', $self->naa, $oui, '0', $fid, $serial, $port );
    },
);

sub _build_naa { return 5 }
sub _build_oui { return Device::OUI->new( '0060E8' ) }

# HDS seems to ignore the first character of the vendor_id, as far as I can
# tell it is always 0
has 'family_id' => ( is => 'rw', isa => 'Str', lazy_build => 1 );
sub _build_family_id { return substr( shift->vendor_id, 1, 2 ) }

has 'serial_number' => ( is => 'rw', isa => 'Str', lazy_build => 1 );
sub _build_serial_number { return hex( substr( shift->vendor_id, 3, 4 ) ) }

has 'port'  => ( is => 'rw', isa => 'Str', lazy_build => 1 );
sub _build_port {
    my $self = shift;
    my $cluster = substr( $self->vendor_id, 7, 1 ) + 1;
    my @ports = qw( A B C D E F G H J K L M N O P Q );
    return $cluster.$ports[ hex( substr( $self->vendor_id, 8, 1 ) ) ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Device::WWN::Hitachi::HDS - Device::WWN subclass for Hitachi HDS WWNs

=head1 DESCRIPTION

This module is a subclass of L<Device::WWN|Device::WWN> which provides
additional information about Hitachi HDS arrays.  These arrays are also
resold by various vendors under other names, including:

    Sun StorEdge
    HP XP series

See L<Device::WWN|Device::WWN> for more information.

=head1 METHODS

=head2 accept_wwn( $wwn )

This is called as a class method by L<Device::WWN> and returns a true value
if the WWN provided can be handled by this subclass.

=head2 family_id

Returns the family ID part of the WWN.

=head2 port

Returns the port the WWN is associated with.

=head2 serial_number

Returns the serial number of the array the WWN is associated with.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-wwn>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Device::WWN|Device::WWN>

L<Device::WWN::Sun::StorEdge|Device::WWN::Sun::StorEdge>

L<Device::WWN::HP::XP|Device::WWN::HP::XP>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

