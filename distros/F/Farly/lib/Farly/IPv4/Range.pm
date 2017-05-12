package Farly::IPv4::Range;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::IPv4::Address;
require Farly::IPv4::Network;
use Farly::IPv4::Object;

our @ISA     = qw(Farly::IPv4::Object);
our $VERSION = '0.26';

sub new {
    my ( $class, $first, $last ) = @_;

    my $self = {
        FIRST => undef,    #::IPv4::Address
        LAST  => undef,    #::IPv4::Address
    };
    bless( $self, $class );

    if ( defined $last ) {
        $self->_init( $first, $last );
    }
    elsif ( defined $first ) {
        my ( $f, $l ) = split( /-|\s+/, $first );
        $self->_init( $f, $l );
    }
    else {
        confess "first last address range required";
    }

    return $self;
}

sub _init {
    my ( $self, $first, $last ) = @_;

    $self->{FIRST} = Farly::IPv4::Address->new($first);
    $self->{LAST}  = Farly::IPv4::Address->new($last);

    confess "First must be less than last"
      if ( $self->first() > $self->last() );
}

sub first {
    return $_[0]->{FIRST}->address();
}

sub last {
    return $_[0]->{LAST}->address();
}

sub as_string {
    my ($self) = @_;
    return join( " ", $self->{FIRST}->as_string(), $self->{LAST}->as_string() );
}

sub adjacent {
    my ( $self, $other ) = @_;
    if ( ( $self->last() + 1 ) == $other->first() ) {
        return 1;
    }
    return 0;
}

sub start {
    return $_[0]->{FIRST};
}

sub end {
    return $_[0]->{LAST};
}

sub as_network {
    my ($self) = @_;
    my $first  = $self->first();
    my $last   = $self->last();
    my @list;
    my $mask;
    my $host_mask = 4294967295;    #0XFFFFFFFF

    #start from the first address in the range
    while ( $first < $last ) {

        # start from the /32 mask and work downwards
        my $current_mask = $host_mask;

        # check if the current mask results in first being a network number
        while ( $first == ( $first & $current_mask ) ) {

            # if the current mask is still in the range try a bigger mask
            my $inverse_mask = ~$current_mask & $host_mask;
            if ( ( $first + $inverse_mask ) <= $last ) {
                $mask         = $current_mask;
                $current_mask = ( $current_mask << 1 ) & $host_mask;
            }
            else {
                last;
            }
        }

        if ( $mask == 4294967295 ) {
            push @list, Farly::IPv4::Address->new($first);
        }
        else {
            push @list, Farly::IPv4::Network->new("$first $mask");
        }

        $first = $first + ( ~$mask & $host_mask ) + 1;

        if ( $first == $last ) {
            push @list, Farly::IPv4::Address->new($first);
        }

    }

    return @list;
}

sub iter {
    my @iter = ( Farly::IPv4::Range->new( $_[0]->first(), $_[0]->last() ) );
    return @iter;
}

1;
__END__

=head1 NAME

Farly::IPv4::Range - IPv4 range class

=head1 DESCRIPTION

This class represents an IPv4 address range.

Inherits from Farly::IPv4::Object.

=head1 METHODS

=head2 new( <string> )

The constructor accepts a dotted decimal format, or 32 bit integer
format, IP address range with the first address separated from the last 
address by a space or dash.

 my $ip_range = Farly::IPv4::Range->new( "10.0.0.1 10.0.0.25" );
 my $ip_range = Farly::IPv4::Range->new( "10.0.0.1-10.0.0.25" );

=head2 first()

Returns the first address in the range as a 32 bit integer

  $first_32bit_int_addr = $ip_range->first();

=head2 last()

Returns the last address in the range as a 32 bit integer

  $last_32bit_int_addr = $ip_range->last();

=head2 start()

Returns the first address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_range->start();

=head2 end()

Returns the last address as an Farly::IPv4::Address object

  $ipv4_addr_object = $ip_range->end();

=head2 as_string()

Returns the current Farly::IPv4::Range as a dotted decimal format string

  print $ip_range->as_string();

=head2 as_network()

Return an ARRAY of Farly::IPv4::Network objects containing exactly the same IP 
addresses as the current range.

  my @array = $ip_range->as_network();

=head2 adjacent( <Farly::IPv4::Object> )

Returns true if the other Farly::IPv4::Object's first address immediately
follows the current range's last address.

  $ip_range->adjacent( $other_ipv4_object );

=head2 iter()

Returns an array containing the current Farly::IPv4::Range object.

  my @array = $ip_range->iter();

=head1 COPYRIGHT AND LICENSE

Farly::IPv4::Range
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
