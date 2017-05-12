package Farly::Transport::PortRange;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::Transport::Port;
use Farly::Transport::Object;

our $VERSION = '0.26';
our @ISA     = qw(Farly::Transport::Object);

sub new {
    my ( $class, $first, $last ) = @_;

    my $self = {
        LOW  => undef,
        HIGH => undef,
    };
    bless( $self, $class );

    if ( defined $last ) {
        $self->{LOW}  = Farly::Transport::Port->new($first);
        $self->{HIGH} = Farly::Transport::Port->new($last);
    }
    elsif ( defined $first ) {
        my ( $low, $high ) = split( /-|\s+/, $first );
        $self->{LOW}  = Farly::Transport::Port->new($low);
        $self->{HIGH} = Farly::Transport::Port->new($high);
    }

    confess "invalid port range"
      if ( $self->first() > $self->last() );

    return $self;
}

sub low {
    return $_[0]->{LOW};
}

sub high {
    return $_[0]->{HIGH};
}

sub first {
    return $_[0]->{LOW}->port();
}

sub last {
    return $_[0]->{HIGH}->port();
}

sub as_string {
    my ($self) = @_;
    return join( " ", $self->low()->as_string(), $self->high()->as_string() );
}

sub iter {
    my ($self) = @_;

    my @list;
    my $i = $self->first();

    do {

        push @list, Farly::Transport::Port->new($i);
        $i++;

    } while ( $i < $self->last() );

    return @list;
}

1;
__END__

=head1 NAME

Farly::Transport::PortRange - TCP/UDP port range class

=head1 DESCRIPTION

This class represents a TCP or UDP port number range.

Inherits from Farly::Transport::Object.

=head1 METHODS

=head2 new( <string> )

The constructor accepts port number range with the first port
separated from the last port by a space or dash.

 my $port_range = Farly::Transport::PortRange->new( "1024 65535" );
 my $port_range = Farly::Transport::PortRange->new( "1024-65535" );

=head2 first()

Returns the first port in the range as an integer

  $first_8_bit_int = $port_range->first();

=head2 last()

Returns the last port in the range as an integer

  $last_8_bit_int = $port_range->last();

=head2 as_string()

Returns the current Farly::Transport::PortRange as a string

  print $port_range->as_string();

=head2 iter()

Returns an array containing the all of the port objects in the 
current PortRange object. For use in Set calculations.

  my @array = $port_range->iter();

=head1 COPYRIGHT AND LICENSE

Farly::Transport::PortRange
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
