#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

package Device::Chip::AnalogConverters;
our $VERSION = '0.10';

=head1 NAME

C<Device::Chip::AnalogConverters> - a collection of chip drivers

=head1 DESCRIPTION

This distribution contains a number of L<Device::Chip> drivers for various ADC
and DAC chips.

=cut

=head1 ADCs

=over 2

=item *

L<Device::Chip::ADC121Sx>

=item *

L<Device::Chip::ADS1115>

=item *

L<Device::Chip::LTC2400>

=item *

L<Device::Chip::MCP3221>

=item *

L<Device::Chip::MAX11200>

=item *

L<Device::Chip::MAX1166x>

=back

=head2 SUGGESTED ADC METHODS

=head3 trigger

   $chip->trigger( %args )->get

Optional. This method asks the chip to begin taking a reading.

=head3 read_adc

   $value = $chip->read_adc->get

Obtains the most recent reading performed by the chip, as a plain integer
value. This may be signed or unsigned, scaled to whatever precision the chip
works at.

=head3 read_adc_voltage

   $voltage = $chip->read_adc_voltage->get

If the chip contains an internal reference, or in some other way the scale is
known by the driver, this method should be provided that converts the result
of L</read_adc> into an actual signed voltage.

=head3 read_adc_ratio

   $ratio = $chip->read_adc_ratio->get

If the chip (driver) does not have a reference to scale convert the output
directly to a voltage level, then this method should be provided instead that
merely scales the raw reading down by a factor such that the returned value is
a floating-point number between 0 and 1 for unipolar (single-ended unsigned)
readings, or between -1 and 1 for bipolar (differential signed) readings.

=cut

=head1 DACs

=over 2

=item *

L<Device::Chip::AD5691R>

=item *

L<Device::Chip::DAC7513>

=item *

L<Device::Chip::DAC7571>

=item *

L<Device::Chip::MCP4725>

=back

=head2 SUGGESTED DAC METHODS

=head3 write_dac

   $chip->write_dac( $value )->get

Sets the value of the DAC's output as a plain integer value. This may be
signed or unsigned, scaled to whatever precision the chip works at.

=head3 write_dac_voltage

   $chip->write_dac_voltage( $voltage )->get

If the chip contains an internal reference, or in some other way the scale is
known by the driver, this method should be provided that converts the given
voltage into a raw value to invoke L</write_dac> with.

=head3 write_dac_ratio

   $chip->write_dac_ratio( $ratio )->get

If the chip (driver) does not have a reference to scale convert a given
voltage to a DAC code value, then this method should be provided instead that
takes a given ratio, as a floating-point number between 0 and 1 for unipolar
(single-ended unsigned) outputs or between -1 and 1 for bipolar (differential
signed) outputs, and scales it by a suitable factor.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
