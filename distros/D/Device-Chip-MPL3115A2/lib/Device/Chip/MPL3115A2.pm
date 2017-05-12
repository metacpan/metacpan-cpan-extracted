#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::Chip::MPL3115A2;

use strict;
use warnings;
use base qw( Device::Chip::Base::RegisteredI2C );

use utf8;

our $VERSION = '0.05';

use Carp;

use Future::Utils qw( repeat );

use Data::Bitfield qw( bitfield boolfield enumfield );

=encoding UTF-8

=head1 NAME

C<Device::Chip::MPL3115A2> - chip driver for a F<MPL3115A2>

=head1 SYNOPSIS

 use Device::Chip::MPL3115A2;

 my $chip = Device::Chip::MPL3115A2->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 printf "Current pressure is %.2f kPa\n",
    $chip->read_pressure->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Freescale Semiconductor> F<MPL3115A2> attached to a computer via an I²C
adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub I2C_options
{
   return (
      # This device has a constant address
      addr        => 0x60,
      max_bitrate => 100E3,
   );
}

use constant WHO_AM_I_ID => 0xC4;

use constant {
   REG_STATUS          => 0x00,
   REG_OUT_P_MSB       => 0x01,
   REG_OUT_P_CSB       => 0x02,
   REG_OUT_P_LSB       => 0x03,
   REG_OUT_T_MSB       => 0x04,
   REG_OUT_T_LSB       => 0x05,
   REG_DR_STATUS       => 0x06,
   REG_OUT_P_DELTA_MSB => 0x07,
   REG_OUT_P_DELTA_CSB => 0x08,
   REG_OUT_P_DELTA_LSB => 0x09,
   REG_OUT_T_DELTA_MSB => 0x0A,
   REG_OUT_T_DELTA_LSB => 0x0B,
   REG_WHO_AM_I        => 0x0C,
   REG_F_STATUS        => 0x0D,
   REG_F_DATA          => 0x0E,
   REG_F_SETUP         => 0x0F,
   REG_TIME_DLY        => 0x10,
   REG_SYSMOD          => 0x11,
   REG_INT_SOURCE      => 0x12,
   REG_PT_DATA_CFG     => 0x13,
   REG_BAR_IN_MSB      => 0x14,
   REG_BAR_IN_LSB      => 0x15,
   REG_P_TGT_MSB       => 0x16,
   REG_P_TGT_LSB       => 0x17,
   REG_T_TGT           => 0x18,
   REG_P_WND_MSB       => 0x19,
   REG_P_WND_LSB       => 0x1A,
   REG_T_WND           => 0x1B,
   REG_P_MIN_MSB       => 0x1C,
   REG_P_MIN_CSB       => 0x1D,
   REG_P_MIN_LSB       => 0x1E,
   REG_T_MIN_MSB       => 0x1F,
   REG_T_MIN_LSB       => 0x20,
   REG_P_MAX_MSB       => 0x21,
   REG_P_MAX_CSB       => 0x22,
   REG_P_MAX_LSB       => 0x23,
   REG_T_MAX_MSB       => 0x24,
   REG_T_MAX_LSB       => 0x25,
   REG_CTRL_REG1       => 0x26,
   REG_CTRL_REG2       => 0x27,
   REG_CTRL_REG3       => 0x28,
   REG_CTRL_REG4       => 0x29,
   REG_CTRL_REG5       => 0x2A,
   REG_OFF_P           => 0x2B,
   REG_OFF_T           => 0x2C,
   REG_OFF_H           => 0x2D,
};

# Represent CTRL_REG1 to CTRL_REG3 as one three-byte field
bitfield CTRL_REG =>
   # CTRL_REG1
   SBYB => enumfield( 0, qw( STANDBY ACTIVE )),
   OST  => boolfield( 1 ),
   RST  => boolfield( 2 ),
   OS   => enumfield( 3, qw( 1 2 4 8 16 32 64 128 )),
   RAW  => boolfield( 6 ),
   ALT  => boolfield( 7 ),

   # CTRL_REG2
   ST          => enumfield( 8, map { 1 << $_ } 0 .. 15 ),
   ALARM_SEL   => boolfield( 13 ),
   LOAD_OUTPUT => boolfield( 14 ),

   # CTRL_REG3
   IPOL1  => boolfield( 16 ),
   PP_OD1 => boolfield( 17 ),
   IPOL2  => boolfield( 20 ),
   PP_OD2 => boolfield( 21 );

# Converted pressure
sub _mplread_p { $_[0]->read_reg( $_[1], 3 )
                  ->then( sub { Future->done( unpack( "L>", "\0" . $_[0] ) / 64 ) } ) }

# Converted altitude
sub _mplread_a { $_[0]->read_reg( $_[1], 3 )
                  ->then( sub {
                        my ( $msb, $lsb ) = unpack "s>C", $_[0];
                        Future->done( $msb + ( $lsb / 256 ) ); }) }

# Converted temperature
sub _mplread_t { $_[0]->read_reg( $_[1], 2 )
                  ->then( sub {
                        my ( $msb, $lsb ) = unpack "cC", $_[0];
                        Future->done( $msb + ( $lsb / 256 ) ) }) }

=head1 ACCESSORS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference of the contents of control registers C<CTRL_REG1>
to C<CTRL_REG3>, using fields named from the data sheet.

=head2 change_config

   $chip->change_config( %changes )->get

Writes updates to the control registers C<CTRL_REG1> to C<CTRL_REG3>. This
will be performed as a read-modify-write operation, so any fields not given
as arguments to this method will retain their current values.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient. This cache will not respect the
"one-shot" nature of the C<OST> and C<RST> bits.

=cut

sub _cached_read_ctrlreg
{
   my $self = shift;

   defined $self->{configbytes}
      ? return Future->done( $self->{configbytes} )
      : return $self->read_reg( REG_CTRL_REG1, 3 )
}

sub read_config
{
   my $self = shift;

   $self->_cached_read_ctrlreg->then( sub {
      my ( $bytes ) = @_;
      return Future->done( { unpack_CTRL_REG( unpack "L<", $bytes . "\0" ) } );
   });
}

sub change_config
{
   my $self = shift;
   my %changes = @_;

   $self->read_config->then( sub {
      my ( $config ) = @_;
      $config->{$_} = $changes{$_} for keys %changes;

      my $bytes = $self->{configbytes} =
         substr pack( "L<", pack_CTRL_REG( %$config ) ), 0, 3;

      $self->write_reg( REG_CTRL_REG1, $bytes );
   });
}

=head2 get_sealevel_pressure

=head2 set_sealevel_pressure

   $pressure = $chip->get_sealevel_pressure->get

   $chip->set_sealevel_pressure->get( $pressure )

Read or write the barometric pressure calibration register which is used to
convert pressure to altitude when the chip is in altimeter mode, in Pascals.
The default value is 101,326 Pa.

=cut

sub get_sealevel_pressure {
   $_[0]->read_reg( REG_BAR_IN_MSB, 2 )
      ->transform( done => sub { unpack( "S<", $_[0] ) * 2 } );
}

sub set_sealevel_pressure {
   $_[0]->write_reg( REG_BAR_IN_MSB, pack "S<", $_[1] / 2 )
}

=head2 read_pressure

   $pressure = $chip->read_pressure->get

Returns the value of the C<OUT_P_*> registers, suitably converted into
Pascals. (The chip must be in barometer mode and must I<not> be in C<RAW> mode
for the conversion to work).

=cut

sub read_pressure { shift->_mplread_p( REG_OUT_P_MSB ) }

=head2 read_altitude

   $altitude = $chip->read_altitude->get

Returns the value of the C<OUT_P_*> registers, suitably converted into metres.
(The chip must be in altimeter mode and must I<not> be in C<RAW> mode for the
conversion to work).

=cut

sub read_altitude { shift->_mplread_a( REG_OUT_P_MSB ) }

=head2 read_temperature

   $temperature = $chip->read_temperature->get

Returns the value of the C<OUT_T_*> registers, suitable converted into degrees
C. (The chip must I<not> be in C<RAW> mode for the conversion to work).

=cut

sub read_temperature { shift->_mplread_t( REG_OUT_T_MSB ) }

=head2 read_min_pressure

=head2 read_max_pressure

   $pressure = $chip->read_min_pressure->get

   $pressure = $chip->read_max_pressure->get

Returns the values of the C<P_MIN> and C<P_MAX> registers, suitably converted
into Pascals.

=head2 clear_min_pressure

=head2 clear_max_pressure

   $chip->clear_min_pressure->get

   $chip->clear_max_pressure->get

Clear the C<P_MIN> or C<P_MAX> registers, resetting them to start again from
the next measurement.

=cut

sub read_min_pressure { shift->_mplread_p( REG_P_MIN_MSB ) }
sub read_max_pressure { shift->_mplread_p( REG_P_MAX_MSB ) }

sub clear_min_pressure { shift->write_reg( REG_P_MIN_MSB, "\x00\x00\x00" ) }
sub clear_max_pressure { shift->write_reg( REG_P_MAX_MSB, "\x00\x00\x00" ) }

=head2 read_min_altitude

=head2 read_max_altitude

   $altitude = $chip->read_min_altitude->get

   $altitude = $chip->read_max_altitude->get

Returns the values of the C<P_MIN> and C<P_MAX> registers, suitably converted
into metres.

=cut

=head2 clear_min_altitude

=head2 clear_max_altitude

   $chip->clear_min_altitude->get

   $chip->clear_max_altitude->get

Clear the C<P_MIN> or C<P_MAX> registers, resetting them to start again from
the next measurement.

=cut

sub read_min_altitude { shift->_mplread_a( REG_P_MIN_MSB ) }
sub read_max_altitude { shift->_mplread_a( REG_P_MAX_MSB ) }

*clear_min_altitude = \&clear_min_pressure;
*clear_max_altitude = \&clear_max_pressure;

=head2 read_min_temperature

=head2 read_max_temperature

   $temperature = $chip->read_min_temperature->get

   $temperature = $chip->read_max_temperature->get

Returns the values of the C<T_MIN> and C<T_MAX> registers, suitably converted
into metres.

=head2 clear_min_temperature

=head2 clear_max_temperature

   $chip->clear_min_temperature->get

   $chip->clear_max_temperature->get

Clear the C<T_MIN> or C<T_MAX> registers, resetting them to start again from
the next measurement.

=cut

sub read_min_temperature { shift->_mplread_t( REG_T_MIN_MSB ) }
sub read_max_temperature { shift->_mplread_t( REG_T_MAX_MSB ) }

sub clear_min_temperature { shift->write_reg( REG_T_MIN_MSB, "\x00\x00" ) }
sub clear_max_temperature { shift->write_reg( REG_T_MAX_MSB, "\x00\x00" ) }

=head1 METHODS

=cut

=head2 check_id

   $chip->check_id->get

Reads the C<WHO_AM_I> register and checks for a valid ID result. The returned
future fails if the expected result is not received.

=cut

sub check_id
{
   my $self = shift;

   $self->read_reg( REG_WHO_AM_I, 1 )->then( sub {
      my ( $val ) = @_;
      my $id = unpack "C", $val;
      $id == WHO_AM_I_ID or
         die sprintf "Incorrect response from WHO_AM_I register (got %02X, expected %02X)\n",
            $id, WHO_AM_I_ID;

      Future->done( $self );
   });
}

=head2 start_oneshot

   $chip->start_oneshot->get

Sets the C<OST> bit of C<CTRL_REG1> to start a one-shot measurement when in
standby mode. After calling this method you will need to use
C<busywait_oneshot> to wait for the measurement to finish, or rely somehow on
the interrupts.

=cut

sub start_oneshot
{
   my $self = shift;

   $self->_cached_read_ctrlreg->then( sub {
      my ( $bytes ) = @_;
      my $ctrl_reg1 = substr( $bytes, 0, 1 ) | "\x02"; # Set OST bit
      $self->write_reg( REG_CTRL_REG1, $ctrl_reg1 );
   });
}

=head2 busywait_oneshot

   $chip->busywait_oneshot->get

Repeatedly reads the C<OST> bit of C<CTRL_REG1> until it becomes clear.

=cut

sub busywait_oneshot
{
   my $self = shift;

   repeat {
      $self->read_reg( REG_CTRL_REG1, 1 )->then( sub {
         Future->done( ord( $_[0] ) & 0x02 )
      });
   } until => sub { !$_[0]->failure and !$_[0]->get };
}

=head2 oneshot

   $chip->oneshot->get

A convenient wrapper around C<start_oneshot> and C<busywait_oneshot>.

=cut

sub oneshot
{
   my $self = shift;

   $self->start_oneshot->then( sub {
      $self->busywait_oneshot
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
