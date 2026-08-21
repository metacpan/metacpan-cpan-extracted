#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024-2026 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

use utf8;

package Device::Chip::SGP4x 0.03;
class Device::Chip::SGP4x
   :isa(Device::Chip::From::Sensirion);

use Sublike::Extended 0.29 'method';

use Future::AsyncAwait;

=encoding UTF-8

=head1 NAME

C<Device::Chip::SGP4x> - chip driver for F<SGP40> and F<SGP41>

=head1 SYNOPSIS

=for highlighter language=perl

   use Device::Chip::SGP4x;
   use Future::AsyncAwait;

   my $chip = Device::Chip::SGP4x->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->execute_conditioning;

   while(1) {
      await Future::IO->sleep(1);

      my ( $raw_NOx, $raw_VOC ) = await $chip->measure_raw_signals;
      printf "NOx = %d, VOC = %d\n", $raw_NOx, $raw_VOC;
   }

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Sensirion> F<SGP40> or F<SGP41> attached to a computer via I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

method I2C_options ( %params )
{
   my $addr = delete $params{addr} // 0x59;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 execute_conditioning

   await $chip->execute_conditioning;

Performs a conditioning operation.

=cut

async method execute_conditioning ()
{
   my $result = await $self->_cmd( 0x2612,
      words_out => [ 0x8000, 0x6666 ],
      delay     => 0.050,
      read      => 1,
   );

   return;
}

=head2 execute_self_test

   await $chip->execute_self_test;

Performs a self-test operation.

=cut

async method execute_self_test ()
{
   my $result = await $self->_cmd( 0x280E, delay => 0.320, read => 1 );

   my $NOx_OK = $result & (1<<1);
   my $VOC_OK = $result & (1<<0);

   die "NOx failed" if !$NOx_OK;
   die "VOC failed" if !$VOC_OK;

   return;
}

=head2 measure_raw_signals

   ( $adc_VOC, $adc_NOx ) = await $chip->measure_raw_signals;

Performs a sampling cycle and returns the raw ADC values from the sensor
elements.

Optionally, compensation values for humidity and temperature can be passed as
named parameters. If not supplied, the following defaults apply:

   ( $adc_VOC, $adc_NOx ) = await $chip->measure_raw_signals(
      humidity    => 50,  # in units of % RH
      temperature => 25,  # in units of degrees C
   );

=cut

my sub _clamp_u16 ( $val )
{
   return 0      if $val < 0;
   return 0xFFFF if $val > 0xFFFF;
   return int( $val + 0.5 );
}

async method measure_raw_signals (
   :$humidity    = 50,
   :$temperature = 25,
) {
   my $hword = _clamp_u16 $humidity * 0xFFFF / 100;
   my $tword = _clamp_u16 +( $temperature + 45 ) * 0xFFFF / 175;

   my @words = await $self->_cmd( 0x2619,
      words_out => [ $hword, $tword ],
      delay     => 0.050,
      read      => 2,
   );

   return @words;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
