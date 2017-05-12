package Device::WWN::EMC::Symmetrix;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
extends 'Device::WWN';
use Sub::Exporter -setup => {
    exports => [qw(
        wwn_to_serial_and_port
        serial_and_port_to_wwn
        is_valid_port_number
    )]
};
use Device::WWN::Carp;

has '+wwn'  => (
    lazy        => 1,
    default     => sub {
        my $self = shift;
        croak "Can't generate WWN without serial number"
            unless $self->has_serial_number;
        croak "Can't generate WWN without port"
            unless $self->has_port;
        return serial_and_port_to_wwn( $self->serial_number, $self->port );
    },
);

sub accept_wwn {
    my ( $self, $wwn ) = @_;
    return $wwn =~ /^5006048/;
}

has 'serial_number' => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
    trigger     => sub {
        my ( $self, $val ) = @_;
        if ( length $val != 9 ) { croak "serial_number must be 9 digits" }
        if ( $val =~ /\D/ ) { croak "serial_number must contain only digits" }
    },
);
sub _build_serial_number {
    my $self = shift;
    my ( $serial, $port ) = wwn_to_serial_and_port( $self->normalized );
    return $serial;
}

has 'port'      => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);
sub _build_port {
    my $self = shift;
    my ( $serial, $port ) = wwn_to_serial_and_port( $self->normalized );
    return $port;
}

sub wwn_to_serial_and_port {
    my $wwn = Device::WWN::normalize_wwn( shift );
    local $_ = $wwn;
    s/^5006048// || croak "$wwn is not an EMC Symmetrix WWN";

    my @names = qw( AA BA AB BB );

    # last character is the port number
    s/([a-f0-9])$//i || croak "Invalid WWN '$wwn'";
    my $num = hex( $1 ) + 1;

    my $binary = unpack( "B*", pack( "H*", $_ ) );
    $binary =~ s/(\d\d)$// or croak "Invalid WWN '$wwn'";
    my $let = $names[ oct( '0b'.$1 ) ];

    my $serial = oct( '0b'.$binary );
    return ( $serial, sprintf( '%02d%2s', $num, $let ) );
}

sub serial_and_port_to_wwn {
    my ( $serial, $port ) = @_;
    croak "Serial number must be 9 digits" unless length( $serial ) == 9;
    croak "Serial number must be all numeric" if $serial =~ /\D/;
    $port =~ /^(\d+)([AB]{1,2})$/i or croak "Invalid port";
    my %names = qw( AA 00 BA 01 AB 10 BB 11 A 00 B 01 );
    croak "Invalid port '$port'" unless is_valid_port_number( $1 );
    my $num = sprintf( '%x', $1 - 1 );
    my $let = $names{ uc $2 } || croak "Invalid port '$port'";

    my $binary = sprintf( '%b', $serial );
    $binary =~ s/(\d\d)$// or croak "Invalid serial number '$serial'";
    $let = sprintf( '%x', oct( '0b'.$1.$let ) );

    return '5006048'.sprintf( '%x', oct( '0b'.$binary ) ).$let.$num;
}

sub is_valid_port_number {
    my $n = shift;
    return 0 if $n < 1 || $n > 16;
    return 0 if $n == 2;
    return 0 if ( $n >= 7 && $n <= 10 );
    return 1;
}

sub _build_naa { return '5' }
sub _build_oui { return Device::OUI->new( '006048' ) }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Device::WWN::EMC::Symmetrix - Device::WWN subclass for EMC Symmetrix WWNs

=head1 DESCRIPTION

This is a L<Device::WWN> subclass that handles WWNs from EMC Symmetrix storage
arrays.

See L<Device::WWN|Device::WWN> for more information.

=head1 METHODS

=head2 accept_wwn( $wwn )

This is called as a class method by L<Device::WWN> and returns a true value
if the WWN provided can be handled by this subclass.

=head1 FUNCTIONS

Although this module is entirely object oriented, there are a handful of
utility functions that you can import from this module if you find a need
for them.  Nothing is exported by default, so if you want to import any of
them you need to say so explicitly:

    use Device::WWN qw( ... );

You can get all of them by importing the ':all' tag:

    use Device::WWN ':all';

The exporting is handled by L<Sub::Exporter|Sub::Exporter>.

=head2 wwn_to_serial_and_port( $wwn )

Given a Symmetrix WWN, returns the serial number and port.

=head2 serial_and_port_to_wwn( $serial, $port )

Given a serial number and port, returns the appropriate WWN.

=head2 is_valid_port_number( $port_number );

Given a port number (just the numeric part) returns true if it is a valid
port number.

    Valid Symmetrix Port Numbers:
        Model       Valid Ports
        3330        03,14,15,16
        3400/3830   01,04,05,12,13,16
        3700/3930   03,04,05,06,11,12,13,14

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-wwn>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Device::WWN|Device::WWN>

L<http://www.jasonkohles.com/software/device-wwn>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

