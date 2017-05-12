package Farly::IPv4::Network;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::IPv4::Object;
use Farly::IPv4::Address;
require Farly::IPv4::Range;

our @ISA     = qw(Farly::IPv4::Object);
our $VERSION = '0.26';

sub new {
    my ( $class, $network ) = @_;
    confess "IP address and subnet mask required"
      unless ($network);

    my $self = {
        NETWORK => undef,    #Farly::IPv4::Address object
        MASK    => undef     #Farly::IPv4::Address object
    };
    bless( $self, $class );

    $self->_init($network);

    return $self;
}

sub _init {
    my ( $self, $network ) = @_;

    $network =~ s/^\s+|\s+$//g;

    my $address;
    my $mask;
    my $bits;

    if ( $network =~ /^((\d{1,3})((\.)(\d{1,3})){3})\s+((\d{1,3})((\.)(\d{1,3})){3})$/ )
    {
        ( $address, $mask ) = split( /\s+/, $network );
    }
    elsif ( $network =~ /^(\d{1,3}(\.\d{1,3}){3})(\/)(\d+)$/ ) {
        ( $address, $bits ) = split( "/", $network );
        $mask = $self->_bits_to_mask($bits);
    }
    elsif ( $network =~ /^\d+\s+\d+$/ ) {
        ( $address, $mask ) = split( /\s+/, $network );
    }
    else {
        confess "Invalid input $network";
    }

    $self->_set_address($address);
    $self->_set_mask($mask);
}

sub _set_address {
    my ( $self, $address ) = @_;
    $self->{NETWORK} = Farly::IPv4::Address->new($address);
}

sub _set_mask {
    my ( $self, $mask ) = @_;

    if ( $mask =~ /0.0.0.0/ ) {
        $self->{MASK} = Farly::IPv4::Address->new($mask);
    }
    elsif ( $mask =~ /^0/ ) {
        my $ip = Farly::IPv4::Address->new($mask);
        $self->{MASK} = Farly::IPv4::Address->new( $ip->inverse() );
    }
    else {
        $self->{MASK} = Farly::IPv4::Address->new($mask);
    }

    $self->_is_valid_mask();
}

sub _bits_to_mask {
    my ( $self, $bits ) = @_;
    if ( $bits >= 0 && $bits <= 32 ) {
        my $zeroBits = 32 - $bits;
        my $ip       = ( 1 << $zeroBits ) - 1;
        return ~$ip & 4294967295;
    }
    else {
        confess "$bits is not a valid subnet mask";
    }
}

sub _is_valid_mask {
    my $mask = $_[0]->{MASK}->address();
    my $current_bit;
    my $flag = 0;

    for ( my $i = 0 ; $i < 32 ; ++$i ) {
        $current_bit = ( $mask >> $i ) & 1;
        if ( $current_bit == 1 ) {
            $flag = 1;
        }
        if ( ( $flag == 1 ) && ( $current_bit == 0 ) ) {
            confess "$mask is not a valid subnet mask";
        }
    }

    return 1;
}

sub address {
    return $_[0]->{NETWORK}->address();
}

sub network {
    return $_[0]->{NETWORK}->address() & $_[0]->{MASK}->address();
}

sub mask {
    return $_[0]->{MASK};
}

sub inverse_mask {
    return $_[0]->mask()->inverse();
}

sub first {
    return ( $_[0]->network() );
}

sub last {
    return ( $_[0]->network() + $_[0]->inverse_mask() );
}

sub as_string {
    return join( " ", $_[0]->network_address()->as_string(), $_[0]->mask()->as_string() );
}

sub as_wc_string {
    return join( " ", $_[0]->network_address()->as_string(), $_[0]->wc_mask()->as_string() );
}

sub network_address {
    return Farly::IPv4::Address->new( $_[0]->network() );
}

sub wc_mask {
    return Farly::IPv4::Address->new( $_[0]->inverse_mask() );
}

sub broadcast_address {
    return Farly::IPv4::Address->new( $_[0]->network() + $_[0]->inverse_mask() );
}

sub start {
    return $_[0]->network_address();
}

sub end {
    return $_[0]->broadcast_address();
}

sub iter {
    my @iter = ( Farly::IPv4::Range->new( $_[0]->first(), $_[0]->last() ) );
    return @iter;
}

1;
__END__

=head1 NAME

Farly::IPv4::Network - IPv4 network class

=head1 DESCRIPTION

This class represents an IPv4 network.

Inherits from Farly::IPv4::Object.

=head1 METHODS

=head2 new( <string> )

The constructor accepts a dotted decimal format address and mask
or CIDR format network.

 my $ip_network = Farly::IPv4::Network->new( "10.0.0.0 255.0.0.0" );
 my $ip_network = Farly::IPv4::Network->new( "10.0.0.0/8" );

=head2 address()

Returns the 32 bit integer network address

  $32bit_int_network_addr = $ip_network->address();

=head2 mask()

Returns the network mask Farly::IPv4:Address object

  my $mask_object = $ip_network->inverse_mask()

=head2 inverse_mask()

Returns the bit wise logical not of the 32 bit integer network mask IP address

 my $32bit_int_inverse_mask = $ip_network->inverse_mask()

=head2 network_address()

Returns the network address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_network->network_address();

=head2 broadcast_address

Returns the broadcast address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_network->broadcast_address();

=head2 first()

Returns the 32 bit integer network address

  $32bit_int_network_addr = $ip_network->first();

=head2 last()

Returns the 32 bit integer network broadcast IP address

  $32bit_int_network_addr = $ip_network->last();

=head2 start()

Returns the network address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_network->start();

=head2 end()

Returns the broadcast address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_network->end();

=head2 as_string()

Returns the current Farly::IPv4::Network as a dotted decimal format string

  print $ip_network->as_string();

=head2 as_wc_string

Returns the current Farly::IPv4::Network as a dotted decimal format string
with a wild card mask

  print $ip_network->as_wc_string();

=head2 iter()

Returns an array containing the current IP network as a Farly::IPv4::Range
object.

  my @array = $ip->iter();

=head1 COPYRIGHT AND LICENSE

Farly::IPv4::Network
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
