#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package Device::Chip::MAX11200;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.05';

use Carp;
use Future::AsyncAwait;
use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );
use List::Util qw( first );

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::MAX11200> - chip driver for F<MAX11200>

=head1 SYNOPSIS

 use Device::Chip::MAX11200;

 my $chip = Device::Chip::MAX11200->new;
 $chip->mound( Device::Chip::Adapter::...->new )->get;

 $chip->trigger->get;

 printf "The reading is %d\n", $chip->read_adc->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a F<Maxim>
F<MAX11200> or F<MAX11210> chip.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 2E6,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

use constant {
   REG_STAT  => 0,
   REG_CTRL1 => 1,
   REG_CTRL2 => 2,
   REG_CTRL3 => 3,
   REG_DATA  => 4,
   REG_SOC   => 5,
   REG_SGC   => 6,
   REG_SCOC  => 7,
   REG_SCGC  => 8,
};

async sub read_register
{
   my $self = shift;
   my ( $reg, $len ) = @_;

   $len //= 1;

   my $bytes = await $self->protocol->readwrite(
      pack "C a*", 0xC1 | ( $reg << 1 ), "\0" x $len
   );

   return substr $bytes, 1;
}

sub write_register
{
   my $self = shift;
   my ( $reg, $val ) = @_;

   $self->protocol->write(
      pack "C a*", 0xC0 | ( $reg << 1 ), $val
   );
}

my @RATES = qw( 1 2.5 5 10 15 30 60 120 );

use constant {
   CMD_SELFCAL   => 0x10,
   CMD_SYSOCAL   => 0x20,
   CMD_SYSGCAL   => 0x30,
   CMD_POWERDOWN => 0x08,
   CMD_CONV      => 0,
};

sub command
{
   my $self = shift;
   my ( $cmd ) = @_;

   $self->protocol->write( pack "C", 0x80 | $cmd );
}

=head2 read_status

   $status = $chip->read_status->get

Returns a C<HASH> reference containing the chip's current status.

   RDY   => 0 | 1
   MSTAT => 0 | 1
   UR    => 0 | 1
   OR    => 0 | 1
   RATE  => 1 | 2.5 | 5 | 10 | 15 | 30 | 60 | 120
   SYSOR => 0 | 1

=cut

bitfield { format => "bytes-LE" }, STAT =>
   RDY   => boolfield(0),
   MSTAT => boolfield(1),
   UR    => boolfield(2),
   OR    => boolfield(3),
   RATE  => enumfield(4, @RATES),
   SYSOR => boolfield(7);

async sub read_status
{
   my $self = shift;

   my $bytes = await $self->read_register( REG_STAT );

   return unpack_STAT( $bytes );
}

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference containing the chip's current configuration.

   SCYCLE => 0 | 1
   FORMAT => "TWOS_COMP" | "OFFSET"
   SIGBUF => 0 | 1
   REFBUF => 0 | 1
   EXTCLK => 0 | 1
   UB     => "UNIPOLAR" | "BIPOLAR"
   LINEF  => "60Hz" | "50Hz"
   NOSCO  => 0 | 1
   NOSCG  => 0 | 1
   NOSYSO => 0 | 1
   NOSYSG => 0 | 1
   DGAIN  => 1 2 4 8 16  # only valid for the MAX11210

=cut

bitfield { format => "bytes-LE" }, CONFIG =>
   # CTRL1
   SCYCLE => boolfield(1),
   FORMAT => enumfield(2, qw( TWOS_COMP OFFSET )),
   SIGBUF => boolfield(3),
   REFBUF => boolfield(4),
   EXTCLK => boolfield(5),
   UB     => enumfield(6, qw( UNIPOLAR BIPOLAR )),
   LINEF  => enumfield(7, qw( 60Hz 50Hz )),
   # CTRL2 is all GPIO control; we'll do that elsewhere
   # CTRL3
   NOSCO  => boolfield(8+1),
   NOSCG  => boolfield(8+2),
   NOSYSO => boolfield(8+3),
   NOSYSG => boolfield(8+4),
   DGAIN  => enumfield(8+5, qw( 1 2 4 8 16 ));

async sub read_config
{
   my $self = shift;

   my ( $ctrl1, $ctrl3 ) = await Future->needs_all(
      $self->read_register( REG_CTRL1 ), $self->read_register( REG_CTRL3 )
   );

   return $self->{config} = { unpack_CONFIG( $ctrl1 . $ctrl3 ) };
}

=head2 change_config

   $chip->change_config( %changes )->get

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

async sub change_config
{
   my $self = shift;
   my %changes = @_;

   my $config = $self->{config} // await $self->read_config;

   $self->{config} = { %$config, %changes };
   my $ctrlb = pack_CONFIG( %{ $self->{config} } );

   await Future->needs_all(
      $self->write_register( REG_CTRL1, substr $ctrlb, 0, 1 ),
      $self->write_register( REG_CTRL3, substr $ctrlb, 1, 1 ),
   );
}

=head2 selfcal

   $chip->selfcal->get

Requests the chip perform a self-calibration.

=cut

sub selfcal
{
   my $self = shift;

   $self->command( CMD_SELFCAL );
}

=head2 syscal_offset

   $chip->syscal_offset->get

Requests the chip perform the offset part of system calibration.

=cut

sub syscal_offset
{
   my $self = shift;

   $self->command( CMD_SYSOCAL );
}

=head2 syscal_gain

   $chip->syscal_gain->get

Requests the chip perform the gain part of system calibration.

=cut

sub syscal_gain
{
   my $self = shift;

   $self->command( CMD_SYSGCAL );
}

=head2 trigger

   $chip->trigger( $rate )->get

Requests the chip perform a conversion of the input level, at the given
rate (which must be one of the values specified for the C<RATE> configuration
option); defaulting to C<120> if not defined. Once the conversion is complete
it can be read using the C<read_adc> method.

=cut

sub trigger
{
   my $self = shift;
   my ( $rate ) = @_;

   $rate //= 120;

   defined( my $rateidx = first { $RATES[$_] == $rate } 0 .. $#RATES )
      or croak "Unrecognised conversion rate $rate";

   $self->command( CMD_CONV | $rateidx );
}

=head2 read_adc

   $value = $chip->read_adc->get

Reads the most recent reading from the result register on the tip. This method
should be called after a suitable delay after the L</trigger> method when in
single cycle mode, or at any time when in continuous mode.

The reading is returned directly from the chip as a plain 24-bit integer,
either signed or unsigned as per the C<FORMAT> configuration.

=cut

async sub read_adc
{
   my $self = shift;

   my $bytes = await $self->read_register( REG_DATA, 3 );

   return unpack "L>", "\0$bytes";
}

=head2 write_gpios

   $chip->write_gpios( $values, $direction )->get

=head2 read_gpios

   $values = $chip->read_gpios->get

Sets or reads the values of the GPIO pins as a 4-bit integer. Bits in the
C<$direction> should be high to put the corresponding pin into output mode, or
low to put it into input mode.

=cut

sub write_gpios
{
   my $self = shift;
   my ( $values, $dir ) = @_;

   $self->write_register( REG_CTRL2, pack "C", ( $dir << 4 ) | $values );
}

async sub read_gpios
{
   my $self = shift;

   my $bytes = await $self->read_register( REG_CTRL2 );

   return 0x0F & unpack "C", $bytes;
}

=head2 Calibration Registers

   $value = $chip->read_selfcal_offset->get;
   $value = $chip->read_selfcal_gain->get;
   $value = $chip->read_syscal_offset->get;
   $value = $chip->read_syscal_gain->get;

   $chip->write_selfcal_offset( $value )->get;
   $chip->write_selfcal_gain( $value )->get;
   $chip->write_syscal_offset( $value )->get;
   $chip->write_syscal_gain( $value )->get;

Reads or writes the values of the calibration registers, as plain 24-bit
integers.

=cut

foreach (
   [ "selfcal_offset", REG_SCOC ],
   [ "selfcal_gain",   REG_SCGC ],
   [ "syscal_offset",  REG_SOC  ],
   [ "syscal_gain",    REG_SGC  ],
) {
   my ( $name, $reg ) = @$_;

   no strict 'refs';

   *{"read_$name"} = async sub {
      my $bytes = await $_[0]->read_register( $reg, 3 );
      return unpack "I>", "\0" . $bytes;
   };

   *{"write_$name"} = sub {
      $_[0]->write_register( $reg,
         substr( pack( "I>", $_[1] ), 1 )
      );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
