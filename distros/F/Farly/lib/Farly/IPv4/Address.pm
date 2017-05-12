package Farly::IPv4::Address;

use 5.008008;
use strict;
use warnings FATAL => 'all';
use Carp;
use Farly::IPv4::Object;

our @ISA     = qw(Farly::IPv4::Object);
our $VERSION = '0.26';

sub new {
    my ( $class, $address ) = @_;

    confess "IP address required"
      unless ( defined($address) );

    carp "invalid constructor arguments"
      if ( scalar(@_) > 2 );

    $address =~ s/\s+//g;

    if ( $address =~ /^((\d{1,3})((\.)(\d{1,3})){3})$/ ) {
        $address = pack( "C4", split( /\./, $address ) );
    }
    elsif ( $address =~ /^\d+$/ ) {
        $address = pack( "N", $address );
    }
    else {
        confess "invalid address $address";
    }

    my $ip = bless( \$address, $class );

    confess "invalid address $address"
      unless ( $ip->address() >= 0 && $ip->address() <= 4294967295 );

    return $ip;
}

sub address {
    return unpack( "N", ${ $_[0] } );
}

sub inverse {
    return ~$_[0]->address() & 4294967295;
}

sub first {
    return $_[0]->address();
}

sub last {
    return $_[0]->address();
}

sub start {
    return Farly::IPv4::Address->new( $_[0]->address() );
}

sub end {
    return Farly::IPv4::Address->new( $_[0]->address() );
}

sub dottedDecimalFormat {
    return join( ".", unpack( 'C4', ${ $_[0] } ) );
}

sub as_string {
    return $_[0]->dottedDecimalFormat();
}

sub iter {
    my @iter = ( Farly::IPv4::Range->new( $_[0]->first(), $_[0]->last() ) );
    return @iter;
}

1;
__END__

=head1 NAME

Farly::IPv4::Address - IPv4 address class

=head1 DESCRIPTION

This class represents an IPv4 address.

Inherits from Farly::IPv4::Object.

=head1 METHODS

=head2 new( <string> )

The constructor accepts a dotted decimal or 32 bit integer format IP address

 my $ip = Farly::IPv4::Address->new( "10.1.2.3" );

=head2 address()

Returns the 32 bit integer IP address

  $32bit_int = $ip->address();

=head2 inverse()

Returns a bit flipped version of the 32 bit integer IP address

  $32bit_int = $ip->inverse();

=head2 first()

Returns the 32 bit integer IP address

  $32bit_int = $ip->first();

=head2 last()

Returns the 32 bit integer IP address

  $32bit_int = $ip->first();

=head2 start()

Returns the current Farly::IPv4::Address object

  $ipv4_addr_object = $ip->start();

=head2 end()

Returns the current Farly::IPv4::Address object

  $ipv4_addr_object = $ip->end();

=head2 as_string()

Returns the current Farly::IPv4::Address as a dotted decimal format string

  print $ip->as_string();

=head2 dottedDecimalFormat()

Returns the current Farly::IPv4::Address as a dotted decimal format string

  print $ip->dottedDecimalFormat();

=head2 iter()

Returns an array containing the current IP address as a Farly::IPv4::Range
object.

  my @array = $ip->iter();

=head1 COPYRIGHT AND LICENSE

Farly::IPv4::Address
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
