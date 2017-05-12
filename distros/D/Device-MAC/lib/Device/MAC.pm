package Device::MAC;
use strict; use warnings;
our $VERSION = '1.00';
use Moose;
use Device::OUI;
use Carp qw( croak );
use overload (
    '<=>' => 'overload_cmp',
    'cmp' => 'overload_cmp',
    '""'  => 'overload_stringify',
    fallback => 1,
);
use Sub::Exporter -setup => {
    exports => [qw( mac_to_integers normalize_mac mac_cmp )],
};

has 'mac'   => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_mac',
    clearer     => 'clear_mac',
    required    => 1,
    trigger     => sub {
        my ( $self, $val ) = @_;
        if ( $val ) {
            $self->clear_mac_dependent
        } else {
            $self->clear_mac;
        }
    },
);

sub clear_mac_dependent {
    my $self = shift;

    $self->clear_is_universal;
    $self->clear_is_local;
    $self->clear_is_unicast;
    $self->clear_is_multicast;
    $self->clear_oui;
    $self->clear_is_eui48;
    $self->clear_is_eui64;
}

has 'oui' => ( is => 'rw', isa => 'Maybe[Device::OUI]', lazy_build => 1 );
sub _build_oui {
    my $self = shift;
    ( my $mac = $self->normalized ) =~ s/[^a-f0-9]//ig;
    return Device::OUI->new( substr( $mac, 0, 6 ) );
}

has 'is_eui48'  => ( is => 'ro', isa => 'Bool', lazy_build  => 1 );
sub _build_is_eui48 { return length( shift->normalized ) == 12 }

has 'is_eui64'  => ( is => 'ro', isa => 'Bool', lazy_build  => 1 );
sub _build_is_eui64 { return length( shift->normalized ) == 16 }

has 'is_unicast'   => ( is => 'ro', isa => 'Bool', lazy_build => 1 );
sub _build_is_unicast { ! shift->is_multicast }

has 'is_multicast' => ( is => 'ro', isa => 'Bool', lazy_build => 1 );
sub _build_is_multicast {
    my $self = shift;
    my @bytes = mac_to_integers( $self->mac );
    return $bytes[0] & 1;
}

has 'is_universal'  => ( is => 'ro', isa => 'Bool', lazy_build => 1 );
sub _build_is_universal { ! shift->is_local }

has 'is_local'     => ( is => 'ro', isa => 'Bool', lazy_build => 1 );
sub _build_is_local {
    my $self = shift;
    my @bytes = mac_to_integers( $self->mac );
    return $bytes[0] & 2;
}

sub mac_to_integers {
    my $mac = shift || return;

    my @parts = grep { length } split( /[^a-f0-9]+/i, "$mac" );
    if ( @parts == 1 ) {
        # 12 characters for EUI-48, 16 for EUI-64
        if ( length $parts[0] == 12 || length $parts[0] == 16 ) { # 0019e3010e72
            local $_ = shift( @parts );
            while ( /([a-f0-9]{2})/ig ) { push( @parts, $1 ) }
            return map { hex } @parts;
        }
    } elsif ( @parts == 6 || @parts == 8 ) { # 00:19:e3:01:0e:72
        return map { hex } @parts;
    } elsif ( @parts == 3 || @parts == 4 ) { # 0019:e301:0e72
        return map { /^(\w\w)(\w\w)$/ && ( hex( $1 ), hex( $2 ) ) } @parts;
    } else {
        croak "Invalid MAC format '$mac'";
    }
}

sub normalize_mac {
    my @ints = mac_to_integers( shift );
    croak "MAC must be 6 bytes long for EUI-48 and 8 bytes long for EUI-64"
        unless ( @ints == 6 || @ints == 8 );
    return join( ':', map { sprintf( '%02x', $_ ) } @ints );
}

sub BUILDARGS {
    my $class = shift;
    if ( @_ == 1 && ! ref $_[0] ) { return { mac => shift() } }
    $class->SUPER::BUILDARGS( @_ );
}

sub overload_stringify { return shift->normalized }

sub overload_cmp { return mac_cmp( pop( @_ ) ? reverse @_ : @_ ) }
sub mac_cmp {
    my @l = mac_to_integers( shift );
    my @r = mac_to_integers( shift );

    while ( @l && @r ) {
        if ( $l[0] == $r[0] ) { shift( @l ); shift( @r ); }
        return $l[0] <=> $r[0];
    }
    return 0;
}

has 'normalized'    => ( is => 'rw', isa => 'Maybe[Str]', lazy_build => 1 );
sub _build_normalized { normalize_mac( shift->mac ) }

1;
__END__

=head1 NAME

Device::MAC - Handle hardware MAC Addresses (EUI-48 and EUI-64)

=head1 SYNOPSIS

    use Device::MAC;
    
    my $mac = Device::MAC->new( '00:19:e3:01:0e:72' );
    print $mac->normalized."\n";
    if ( $mac->is_unicast ) {
        print "\tIs Unicast\n";
    } elsif ( $mac->is_multicast ) {
        print "\tIs Multicast\n";
    }
    if ( $mac->is_local ) {
        print "\tIs Locally Administered\n";
    } elsif ( $mac->is_universal ) {
        print "\tIs Universally Administered\n";
        print "\tVendor: ".$mac->oui->organization."\n";
    }

=head1 DESCRIPTION

This module provides an interface to deal with Media Access Control (or MAC)
addresses.  These are the addresses that uniquely identify a device on a
network.  Although the common case is hardware addresses on network cards,
there are a variety of devices that use this system.  This module supports
both EUI-48 and EUI-64 addresses.

Some devices that use EUI-48 (or MAC-48) addresses include:

    Ethernet
    802.11 wireless networks
    Bluetooth
    IEEE 802.5 token ring
    FDDI
    ATM

Some devices that use EUI-64 addresses include:

    Firewire
    IPv6
    ZigBee / 802.15.4 wireless personal-area networks

=head1 METHODS

=head2 Device::MAC->new( $mac )

Creates and returns a new Device::MAC object.  The MAC value is required.

=head2 $mac->mac

Return the MAC that this object was created with.

=head2 $mac->oui

Returns a L<Device::OUI|Device::OUI> object representing the OUI
(Organizationally Unique Identifier) for the MAC.  This object can give you
information about the vendor of the device represented by this MAC.

=head2 $mac->normalized

Return a 'normalized' MAC value for this object.  The normalized value is in
lower-case hex, with colon separators (such as '00:19:e3:01:0e:72').

L<Device::MAC|Device::MAC> objects have stringification overloaded to return
this value.

=head1 FUNCTIONS / EXPORTS

Although this module is entirely object oriented, there are a handful of
utility functions that you can import from this module if you find a need
for them.  Nothing is exported by default, so if you want to import any of
them you need to say so explicitly:

    use Device::MAC qw( ... );

You can get all of them by importing the ':all' tag:

    use Device::MAC ':all';

The exporting is handled by L<Sub::Exporter|Sub::Exporter>.

=head2 normalize_mac( $mac )

Given a MAC in any common format, normalizes it into a lower-case, zero padded,
hexadecimal format with colon separators.

=head2 mac_cmp( $mac1, $mac2 )

This is a convenience method, given two Device::MAC objects, or two MACs (in
any format acceptable to L</normalize_mac>) will return -1, 0, or 1, depending
on whether the first MAC is less than, equal to, or greater than the second
one.

L<Device::MAC|Device::MAC> objects have C<cmp> and C<< <=> >> overloaded so that
simply comparing them will work as expected.

=head2 mac_to_integers( $mac )

Decodes a MAC into a list of 8 integers.  This is primarily used internally,
but may be useful in some circumstances.

=head1 INTERNAL METHODS

These are internal methods that you generally won't have to worry about.

=head2 BUILDARGS

The BUILDARGS method overloads L<Moose::Object|Moose::Object> to allow you
to pass a single string argument containing the MAC when calling L</new>.

=head2 overload_cmp

A utility method that calls mac_cmp with the appropriate arguments.  Used
by L<overload|overload>.

=head2 overload_stringify

Internal method for L<overload> to call when attempting to stringify the
object.

=head2 clear_mac_dependent

This utility method clears the values of any attributes that depend on the
MAC.  It is called when the MAC attribute it set.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-mac>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<http://www.jasonkohles.com/software/device-mac>

L<http://en.wikipedia.org/wiki/MAC_Address>

L<Device::OUI|Device::OUI>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

