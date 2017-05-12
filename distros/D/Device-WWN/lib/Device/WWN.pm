package Device::WWN;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
use Module::Find ();
use Device::OUI;
use Device::WWN::Carp qw( croak );
use overload (
    '<=>' => 'overload_cmp',
    'cmp' => 'overload_cmp',
    '""'  => 'overload_stringify',
    fallback => 1,
);
use Sub::Exporter -setup => {
    exports => [qw( wwn_to_integers normalize_wwn wwn_cmp )],
};

our @HANDLERS;
sub find_subclasses {
    my $class = shift;
    unless ( @HANDLERS ) {
        @HANDLERS = grep {
            /::/ && $_->isa( __PACKAGE__ )
        } Module::Find::useall( __PACKAGE__ );
    }
    my $wwn = normalize_wwn( shift )
        || croak "Must specify a WWN for find_subclass";
    grep { $_->accept_wwn( $wwn ) } @HANDLERS;
}

has 'wwn'   => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    predicate   => 'has_wwn',
    clearer     => 'clear_wwn',
    trigger     => sub {
        my ( $self, $val ) = @_;
        if ( Scalar::Util::blessed( $self ) eq __PACKAGE__ ) { # not subclass
            my @possible = $self->find_subclasses( $val );
            if ( @possible == 1 ) {
                $self->rebless_class( $possible[0] )
            }
        } elsif ( $self->can( 'accept_wwn' ) ) { # it is a subclass
            $self->accept_wwn( normalize_wwn( $val ) )
                || croak "Invalid WWN '$val' for " . ref( $self );
        }
        if ( $val ) {
            $self->clear_wwn_dependent
        } else {
            $self->clear_wwn;
        }
    },
);

sub rebless_class {
    my ( $self, $new_class ) = @_;
    die "$new_class is not a subclass of ".__PACKAGE__
        unless $self->isa( __PACKAGE__ );
    bless( $self, $new_class );
}

sub clear_wwn_dependent {
    my $self = shift;

    $self->clear_normalized;
    $self->clear_naa;
    $self->clear_oui;
    $self->clear_vendor_code;
    $self->clear_vendor_id;
}

has 'naa'   => ( is => 'rw', isa => 'Int', lazy_build => 1 );
sub _build_naa {
    my $self = shift;
    my $norm = $self->normalized;
    my $naa = substr( $norm, 0, 1 );
    if ( $naa eq '1' ) {
        # 1 - IEEE 803.2 standard 48 bit ID
        # A WWN starting with 1 must start with 1000
        substr( $norm, 1, 3 ) eq '000' || croak "Invalid WWN";
        return 1;
    } elsif ( $naa =~ /^[256]$/ ) {
        # 2 - IEEE 803.2 extended 48-bit ID
        # 5 - IEEE Registered Name
        # 6 - IEEE Extended Registered Name
        return int( $naa );
    } else {
        # everything else is invalid for a WWN
        croak "Invalid WWN (NAA == $naa )";
    }
}

has 'oui' => ( is => 'rw', isa => 'Device::OUI', lazy_build => 1 );
sub _build_oui {
    my $self = shift;
    my $naa = $self->naa;
    my $wwn = $self->normalized;
    my $oui;
    if ( $naa == 1 || $naa == 2 ) {
        $oui = substr( $wwn, 4, 6 );
    } elsif ( $naa == 5 ) {
        $oui = substr( $wwn, 1, 6 );
    } elsif ( $naa == 6 ) {
        die "TODO"; # TODO
    }
    return Device::OUI->new( $oui );
}

has 'vendor_code'  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    lazy_build  => 1,
    trigger     => sub {
        my $self = shift;
        unless ( $self->naa == 2 ) {
            croak "Cannot set vendor_code unless naa is '2'";
        }
    },
);
sub _build_vendor_code {
    my $self = shift;
    my $naa = $self->naa;
    if ( $naa == 2 ) {
        my $wwn = $self->normalized;
        return substr( $wwn, 1, 3 );
    }
    return;
}

has 'vendor_id' => ( is => 'rw', isa => 'Str', lazy_build => 1 );
sub _build_vendor_id {
    my $self = shift;
    my $naa = $self->naa;
    my $wwn = $self->normalized;
    if ( $naa == 1 || $naa == 2 ) {
        return substr( $wwn, 10, 6 );
    } elsif ( $naa == 5 || $naa == 6 ) {
        return substr( $wwn, 7, 9 );
    }
}

sub wwn_to_integers {
    my $wwn = shift || return;

    my @parts = grep { length } split( /[^a-f0-9]+/i, "$wwn" );
    if ( @parts == 1 && length $parts[0] == 16 ) { # 200000e069415402
        local $_ = shift( @parts );
        while ( /([a-f0-9]{2})/ig ) { push( @parts, $1 ) }
        return map { hex } @parts;
    } elsif ( @parts == 8 ) { # 20:00:00:e0:69:41:54:02
        return map { hex } @parts;
    } elsif ( @parts == 4 ) { # 2000:00e0:6941:5402
        return map { /^(\w\w)(\w\w)$/ && ( hex( $1 ), hex( $2 ) ) } @parts;
    } else {
        croak "Invalid WWN format '$wwn'";
    }
}

sub normalize_wwn {
    my @ints = wwn_to_integers( shift );
    croak "Invalid WWN: must be 8 bytes (16 hex characters) long"
        unless @ints == 8;
    return join( '', map { sprintf( '%02x', $_ ) } @ints );
}

sub BUILDARGS {
    my $class = shift;
    if ( @_ == 1 && ! ref $_[0] ) { return { wwn => shift() } }
    $class->SUPER::BUILDARGS( @_ );
}

sub overload_stringify {
    my $self = shift;
    if ( $self->has_wwn ) { return $self->normalized }
    return overload::StrVal( $self );
}

sub overload_cmp { return wwn_cmp( pop( @_ ) ? reverse @_ : @_ ) }
sub wwn_cmp {
    my @l = wwn_to_integers( shift );
    my @r = wwn_to_integers( shift );

    while ( @l && @r ) {
        if ( $l[0] == $r[0] ) { shift( @l ); shift( @r ); }
        return $l[0] <=> $r[0];
    }
    return 0;
}

has 'normalized'    => ( is => 'rw', isa => 'Maybe[Str]', lazy_build => 1 );
sub _build_normalized { normalize_wwn( shift->wwn ) }

1;
__END__

=head1 NAME

Device::WWN - Encode/Decode Fiber Channel World Wide Names

=head1 SYNOPSIS

    use Device::WWN;
    
    my $wwn = Device::WWN->new( '500604872363ee43' );
    print "Serial Number: ".$wwn->serial_number."\n";
    print "Vendor ".$wwn->oui->organization."\n";

=head1 DESCRIPTION

This module provides an interface to decode fiber channel World Wide Name
values (WWN, also called World Wide Identifier or WWID).  The WWN value is
similar to a network cards hardware MAC address, but for fiber channel SAN
networks.

=head1 METHODS

=head2 Device::WWN->find_subclasses( $wwn )

This class method searches through the installed L<Device::WWN> subclasses,
and returns a list of class names of the subclasses that reported they were
able to handle the provided WWN.

=head2 Device::WWN->new( $wwn )

Creates and returns a new Device::WWN object.  The WWN value is required.  Note
that the object you get back might be a subclass of L<Device::WWN>, if there is
a more specific handler class for the WWN you provided.  This is the case for
example when the WWN indicates that it belongs to an EMC Symmetrix or Clariion
array, in which case you will get back a
L<Device::WWN::EMC::Symmetrix|Device::WWN::EMC::Symmatrix> or
L<Device::WWN::EMC::Clariion|Device::WWN::EMC::Clariion> object.  These handler
subclasses are intended to be able to decode the vendor-specific portions of
the WWN, and may be able to give you information such as the storage system
serial number and the port number.

=head2 $wwn->wwn

Return the WWN that this object was created with.

=head2 $wwn->oui

Returns a L<Device::OUI|Device::OUI> object representing the OUI
(Organizationally Unique Identifier) for the WWN.  This object can give you
information about the vendor of the SAN port represented by this WWN.

=head2 $wwn->naa

Returns the 'Network Address Authority' value.  This is the first character of
the WWN, and indicates the format of the WWN itself.  The possible values are:

    1 - IEEE 803.2 standard 48 bit ID
    2 - IEEE 803.2 extended 48-bit ID
    5 - IEEE Registered Name
    6 - IEEE Extended Registered Name

=head2 $wwn->normalized

Return a 'normalized' WWN value for this object.  The normalized value is in
lower-case hex, with no separators (such as '500604872363ee43').

L<Device::WWN|Device::WWN> objects have stringification overloaded to return
this value.  If the object doesn't have a WWN assigned, stringification will
return an object address value just as if it were not overloaded.

=head2 $wwn->vendor_id

Returns the unique vendor ID value for the WWN.

=head2 $wwn->vendor_code

NAA Type 2 defines a 1.5 byte section of the WWN as a 'vendor specific code'.
Some vendors use this to identify the port on a specific device, some use it
simply as an extension of the serial number.  Generally this won't be a very
useful value on it's own, unless there is a L<Device::WWN|Device::WWN> subclass
for the vendor which can decode it.

=head1 FUNCTIONS / EXPORTS

Although this module is entirely object oriented, there are a handful of
utility functions that you can import from this module if you find a need
for them.  Nothing is exported by default, so if you want to import any of
them you need to say so explicitly:

    use Device::WWN qw( ... );

You can get all of them by importing the ':all' tag:

    use Device::WWN ':all';

The exporting is handled by L<Sub::Exporter|Sub::Exporter>.

=head2 normalize_wwn( $wwn )

Given a WWN in any common format, normalizes it into a lower-case, zero padded,
hexadecimal format.

=head2 wwn_cmp( $wwn1, $wwn2 )

This is a convenience method, given two Device::WWN objects, or two WWNs (in
any format acceptable to L</normalize_wwn>) will return -1, 0, or 1, depending
on whether the first WWN is less than, equal to, or greater than the second
one.

L<Device::WWN|Device::WWN> objects have C<cmp> and C<< <=> >> overloaded so that
simply comparing them will work as expected.

=head2 wwn_to_integers( $wwn )

Decodes a WWN into a list of 8 integers.  This is primarily used internally,
but may be useful in some circumstances.

=head1 INTERNAL METHODS

These are internal methods that you generally won't have to worry about.

=head2 BUILDARGS

The BUILDARGS method overloads L<Moose::Object|Moose::Object> to allow you
to pass a single string argument containing the WWN when calling L</new>.

=head2 overload_cmp

A utility method that calls wwn_cmp with the appropriate arguments.  Used
by L<overload|overload>.

=head2 overload_stringify

Internal method for L<overload> to call when attempting to stringify the
object.  If the object has a WWN value, then it will stringify to the
output of L</normalized>, otherwise it will stringify the same as if it had
not been overloaded (using the output of L<overload/StrVal>.

=head2 clear_wwn_dependent

This utility method clears the values of any attributes that depend on the
WWN.  It is called when the WWN attribute it set.  Normally you shouldn't
need to care, but if you are creating a new L<Device::WWN> subclass, then
you should wrap this with a L<Moose/after|Moose 'after' modifier> to also
clear any attributes you add that are dependent on the WWN.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-wwn>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<http://www.jasonkohles.com/software/device-wwn>

L<http://en.wikipedia.org/wiki/World_Wide_Name>

L<Device::OUI|Device::OUI>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

