package Farly::Transport::Protocol;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ( $class, $protocol ) = @_;

    confess "protocol number required" unless ( defined $protocol );

    $protocol =~ s/\s+//g;

    confess "$protocol is not a number"
      unless ( $protocol =~ /^\d+$/ );

    confess "invalid protocol $protocol"
      unless ( ( $protocol >= 0 && $protocol <= 255 ) );

    return bless( \$protocol, $class );
}

sub protocol {
    return ${ $_[0] };
}

sub as_string {
    return ${ $_[0] };
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Protocol') ) {

        return $self->protocol() == $other->protocol();
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Protocol') ) {

        if ( $self->protocol() == 0 ) {
            return 1;
        }

        return $self->equals($other);
    }
}

sub intersects {
    my ( $self, $other ) = @_;

    if ( $self->contains($other) || $other->contains($self) ) {
        return 1;
    }
}

sub compare {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Protocol') ) {
        return $self->protocol() <=> $other->protocol();
    }
}

1;
__END__

=head1 NAME

Farly::Transport::Protocol - TCP/IP protocol class

=head1 DESCRIPTION

Represents an 8 bit TCP/IP protocol integer as an object

=head1 METHODS

=head2 new()

The constructor.

   my $protocol = Farly::Transport::Protocol->new();

No arguments.

=head2 protocol()

Returns the integer protocol number.

  my $8_bit_int = $protocol->protocol();

=head2 equals( <Farly::Transport::Protocol> )

Returns true if the protocols are equal.

  $protocol->equals( $protocol_2 );

=head2 contains( <Farly::Transport::Protocol> )

Returns true if $protocol is "ip" or all protocols.
Returns true if the protocols are equal.

  $protocol->contains( $protocol_2 );

=head2 intersects( <Farly::Transport::Protocol> )

Returns true if the protocols are equal.

  $protocol->intersects( $protocol_2 );

=head2 as_string()

Returns the string value

  $protocol->as_string();

=head1 COPYRIGHT AND LICENSE

Farly::Transport::Protocol
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
along with this program.  If not, see L<http://www.gnu.org/licenses/>.
