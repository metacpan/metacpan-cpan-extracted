#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Device::Chip::PCF857x;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.02';

use constant PROTOCOL => "I2C";

sub I2C_options
{
   my $self = shift;
   my %opts = @_;

   my $addr = $opts{addr} // 0x20;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

sub write
{
   my $self = shift;
   my ( $v ) = @_;

   $self->protocol->write( pack( $self->PACKFMT, $v ) );
}

sub read
{
   my $self = shift;

   $self->protocol->read( $self->READLEN )
      ->then( sub {
         my ( $b ) = @_;
         Future->done( unpack $self->PACKFMT, $b );
      });
}

sub as_adapter
{
   my $self = shift;

   return Device::Chip::PCF857x::_Adapter->new( $self );
}

package # hide from indexer
   Device::Chip::PCF857x::_Adapter;
use base qw( Device::Chip::Adapter );

use Carp;

use Future;

sub new
{
   my $class = shift;
   my ( $chip ) = @_;

   bless {
      chip => $chip,
      mask => $chip->DEFMASK,
      gpiobits => $chip->GPIOBITS,
   }, $class;
}

sub make_protocol_GPIO { Future->done( shift ) }

sub list_gpios
{
   my $self = shift;
   return sort keys %{ $self->{gpiobits} };
}

sub write_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $newmask = $self->{mask};

   foreach my $pin ( keys %$gpios ) {
      my $bit = $self->{gpiobits}{$pin} or
         croak "Unrecognised GPIO pin name $pin";

      $newmask &= ~$bit;
      $newmask |=  $bit if $gpios->{$pin};
   }

   return Future->done if $newmask == $self->{mask};

   $self->{chip}->write( $self->{mask} = $newmask );
}

sub read_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   $self->{chip}->read->then( sub {
      my ( $mask ) = @_;

      my %ret;
      foreach my $pin ( @$gpios ) {
         my $bit = $self->{gpiobits}{$pin} or
            croak "Unrecognised GPIO pin name $pin";

         $ret{$pin} = !!( $mask & $bit );
      }

      Future->done( \%ret );
   });
}

sub tris_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   $self->write_gpios( { map { $_ => 1 } @$gpios } );
}

0x55AA;
