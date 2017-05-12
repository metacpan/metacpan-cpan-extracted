#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::Chip::TSL256x;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.01';

use Data::Bitfield qw( bitfield enumfield );
use Future;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::TSL256x> - chip driver for F<TSL256x>

=head1 SYNOPSIS

 use Device::Chip::TSL256x;

 my $chip = Device::Chip::TSL256x->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 $chip->power(1)->get;

 sleep 1; # Wait for one integration cycle

 printf "Current ambient light level is %.2f lux\n",
    scalar $chip->read_lux->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a F<TAOS>
F<TSL2560> or F<TSL2561> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub I2C_options
{
   my $self = shift;

   return (
      addr        => $self->{addr} // 0x39,
      max_bitrate => 100E3,
   );
}

use constant {
   # Mask bits for the command byte
   CMD_MASK  => 1<<7,
   CMD_CLEAR => 1<<6,
   CMD_WORD  => 1<<5,
   CMD_BLOCK => 1<<4,
};

use constant {
   REG_CONTROL    => 0x00,
   REG_TIMING     => 0x01,
   REG_THRESHLOW  => 0x02, # 16bit
   REG_THRESHHIGH => 0x04, # 16bit
   REG_INTERRUPT  => 0x06,
   REG_ID         => 0x0A,
   REG_DATA0      => 0x0C, # 16bit
   REG_DATA1      => 0x0E, # 16bit
};

bitfield TIMING =>
   GAIN  => enumfield( 4, qw( 1 16 )),
   INTEG => enumfield( 0, qw( 13ms 101ms 402ms ));

sub _read
{
   my $self = shift;
   my ( $addr, $len ) = @_;

   $self->protocol->write_then_read(
      ( pack "C", CMD_MASK | ( $addr & 0x0f ) ), $len
   );
}

sub _write
{
   my $self = shift;
   my ( $addr, $data ) = @_;

   $self->protocol->write(
      pack "C a*", CMD_MASK | ( $addr & 0x0f ), $data
   );
}

=head1 ACCESSORS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference of the contents of timing control register, using
fields named from the data sheet.

   GAIN  => 1 | 16
   INTEG => 13ms | 101ms | 420ms

=head2 change_config

   $chip->change_config( %changes )->get

Writes updates to the timing control register.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient. This cache will not respect the
"one-shot" nature of the C<Manual> bit.

=cut

sub _cached_read_TIMING
{
   my $self = shift;
   defined $self->{TIMINGbytes}
      ? return Future->done( $self->{TIMINGbytes} )
      : return $self->_read( REG_TIMING, 1 )
            ->on_done( sub { $self->{TIMINGbytes} = $_[0] } );
}

sub read_config
{
   my $self = shift;

   $self->_cached_read_TIMING->then( sub {
      return Future->done( { unpack_TIMING( unpack "C", $_[0] ) } );
   });
}

sub change_config
{
   my $self = shift;
   my %changes = @_;

   $self->read_config->then( sub {
      my ( $config ) = @_;
      $config->{$_} = $changes{$_} for keys %changes;

      my $TIMING = $self->{TIMINGbytes} =
         pack "C", pack_TIMING( %$config );

      $self->_write( REG_TIMING, $TIMING );
   });
}

=head2 read_id

   $id = $chip->read_id->get

Returns the chip's ID register value.

=cut

sub read_id
{
   my $self = shift;

   $self->_read( REG_ID, 1 )->then( sub {
      Future->done( unpack "C", $_[0] );
   });
}

=head2 read_data0

=head2 read_data1

   $data0 = $chip->read_data0->get

   $data1 = $chip->read_data1->get

Reads the current values of the ADC channels.

=cut

sub read_data0
{
   my $self = shift;

   $self->_read( REG_DATA0, 2 )->then( sub {
      Future->done( unpack "S<", $_[0] );
   });
}

sub read_data1
{
   my $self = shift;

   $self->_read( REG_DATA1, 2 )->then( sub {
      Future->done( unpack "S<", $_[0] );
   });
}

=head2 read_data

   ( $data0, $data1 ) = $chip->read_data->get

Read the current values of both ADC channels in a single I²C transaction.

=cut

sub read_data
{
   my $self = shift;

   $self->_read( REG_DATA0, 4 )->then( sub {
      Future->done( unpack "S< S<", $_[0] );
   });
}

=head1 METHODS

=cut

=head2 power

   $chip->power( $on )->get

Enables or disables the main power control bits in the C<CONTROL> register.

=cut

sub power
{
   my $self = shift;
   my ( $on ) = @_;

   $self->_write( REG_CONTROL, $on ? "\x03" : "\x00" );
}

=head2 read_lux

   $lux = $chip->read_lux->get

   ( $lux, $data0, $data1 ) = $chip->read_lux->get

Reads the two data registers then performs the appropriate scaling
calculations to return a floating-point number that approximates the light
level in Lux.

Currently this conversion code presumes the contants for the T, FN and CL
chip types.

In list context, also returns the raw C<$data0> and C<$data1> channel values.
The controlling code may wish to use these to adjust the gain if required.

=cut

my %INTEG_to_msec = (
   '13ms'  => 13.7,
   '101ms' => 101,
   '402ms' => 402,
);

sub read_lux
{
   my $self = shift;
   Future->needs_all(
      $self->read_data,
      $self->read_config,
   )->then( sub {
      my ( $data0, $data1, $config ) = @_;

      my $gain = $config->{GAIN};
      my $msec = $INTEG_to_msec{ $config->{INTEG} };

      my $ch0 = $data0 * ( 16 / $gain ) * ( 402 / $msec );
      my $ch1 = $data1 * ( 16 / $gain ) * ( 402 / $msec );

      my $ratio = $ch1 / $ch0;

      # TODO: take account of differing package types.

      my $lux;
      if( $ratio <= 0.52 ) {
         $lux = 0.0304 * $ch0 - 0.062 * $ch0 * ( $ratio ** 1.4 );
      }
      elsif( $ratio <= 0.65 ) {
         $lux = 0.0224 * $ch0 - 0.031 * $ch1;
      }
      elsif( $ratio <= 0.80 ) {
         $lux = 0.0128 * $ch0 - 0.0153 * $ch1;
      }
      elsif( $ratio <= 1.30 ) {
         $lux = 0.00146 * $ch0 - 0.00112 * $ch1;
      }
      else {
         $lux = 0;
      }

      return Future->done( $lux, $data0, $data1 );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
