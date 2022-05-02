#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::ADS1115 0.13;
class Device::Chip::ADS1115
   :isa(Device::Chip::Base::RegisteredI2C);

Device::Chip::Base::RegisteredI2C->VERSION( '0.10' );

use Future::AsyncAwait 0.13; # list-context bugfix

use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );

use constant REG_DATA_SIZE => 16;

=head1 NAME

C<Device::Chip::ADS1115> - chip driver for F<ADS1115>

=head1 SYNOPSIS

   use Device::Chip::ADS1115;
   use Future::AsyncAwait;

   my $chip = Device::Chip::ADS1115->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->change_config( MUX => "0" );
   await $chip->trigger;

   printf "The voltage is %.2fV\n", await $chip->read_adc_voltage;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a chip in
the F<Texas Instruments> F<ADS111x> family, such as the F<ADS1113>, F<ADS1114>
or F<ADS1115>. Due to similarities in hardware, it also works for the
F<ADS101x> family, consisting of F<ADS1013>, F<ADS1014> and F<ADS1015>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

use constant {
   REG_RESULT => 0,
   REG_CONFIG => 1,
   # TODO: threshold config
};

sub I2C_options
{
   return (
      addr        => 0x48,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the chip's current configuration.

   OS   => 0 | 1
   MUX  => "0" | "1" | "2" | "3"            # single-ended
           | "0-1" | "0-3" | "1-3" | "2-3"  # bipolar
   PGA  => "6.144V" | "4.096V" | "2.048V" | "1.024V" | "0.512V" | "0.256V"
   MODE => "CONT" | "SINGLE"
   DR   => 8 | 16 | 32 | 64 | 128 | 250 | 475 | 860

   COMP_MODE => "TRAD" | "WINDOW"
   COMP_POL  => "LOW" | "HIGH"
   COMP_LAT  => 0 | 1
   COMP_QUE  => 1 | 2 | 4 | "DIS"

=cut

bitfield { format => "integer" }, CONFIG =>
   OS   => boolfield(15),
   MUX  => enumfield(12, qw( 0-1 0-3 1-3 2-3 0 1 2 3 )),
   PGA  => enumfield( 9, qw( 6.144V 4.096V 2.048V 1.024V 0.512V 0.256V )),
   MODE => enumfield( 8, qw( CONT SINGLE )),
   DR   => enumfield( 5, qw( 8 16 32 64 128 250 475 860 )),
   COMP_MODE => enumfield(4, qw( TRAD WINDOW )),
   COMP_POL  => enumfield(3, qw( LOW HIGH )),
   COMP_LAT  => boolfield(2),
   COMP_QUE  => enumfield(0, qw( 1 2 4 DIS ));

has $_config;
has $_fullscale_f;

async method read_config ()
{
   my $bytes = await $self->cached_read_reg( REG_CONFIG, 1 );

   return $_config = { unpack_CONFIG( unpack "S>", $bytes ) };
}

=head2 change_config

   await $chip->change_config( %changes );

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

async method change_config ( %changes )
{
   my $config = $_config // await $self->read_config;

   %$config = ( %$config, %changes );

   undef $_fullscale_f if exists $changes{PGA};

   await $self->cached_write_reg( REG_CONFIG, pack "S>", pack_CONFIG( %$config ) );
}

=head2 trigger

   await $chip->trigger;

Set the C<OS> bit configuration bit, which will cause the chip to take a new
reading of the currently-selected input channel when in single-shot mode.

=cut

async method trigger ()
{
   my $config = await $self->read_config;

   # Not "cached" as OS is a volatile bit
   await $self->write_reg( REG_CONFIG, pack "S>", pack_CONFIG( %$config, OS => 1 ) );
}

=head2 read_adc

   $value = await $chip->read_adc;

Reads the most recent reading from the result register on the chip. This
method should be called after a suitable delay after the L</trigger> method
when in single-shot mode, or at any time when in continuous mode.

The reading is returned directly from the chip as a plain 16-bit signed
integer. To convert this into voltage use the L</read_adc_voltage> method.

=cut

async method read_adc ()
{
   my $bytes = await $self->read_reg( REG_RESULT, 1 );

   return unpack "S>", $bytes;
}

async method _fullscale ()
{
   return $_fullscale_f //= do {
      my $config = await $self->read_config;
      ( $config->{PGA} =~ m/(\d\.\d+)V/ )[0];
   };
}

=head2 read_adc_voltage

   $voltage = await $chip->read_adc_voltage;

Reads the most recent reading as per L</read_adc> and converts it into a
voltage level by taking into account the current setting of the C<PGA>
configuration option to scale it.

=cut

async method read_adc_voltage ()
{
   my $f = Future->needs_all( $self->_fullscale, $self->read_adc );
   my ( $fullscale, $reading ) = await $f;

   return ( $reading * $fullscale ) / ( 1 << 15 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
