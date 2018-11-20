#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package Device::Chip::ADS1115;

use strict;
use warnings;
use base qw( Device::Chip::Base::RegisteredI2C );
Device::Chip::Base::RegisteredI2C->VERSION( '0.10' );

our $VERSION = '0.06';

use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );

use constant REG_DATA_SIZE => 16;

=head1 NAME

C<Device::Chip::ADS1115> - chip driver for F<ADS1115>

=head1 SYNOPSIS

 use Device::Chip::ADS1115;

 my $chip = Device::Chip::ADS1115->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 $chip->change_config( MUX => "0" )->get;
 $chip->trigger->get;

 printf "The voltage is %.2fV\n", $chip->read_adc_voltage->get;

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

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_config

   $config = $chip->read_config->get

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

bitfield { format => "bytes-BE" }, CONFIG =>
   OS   => boolfield(15),
   MUX  => enumfield(12, qw( 0-1 0-3 1-3 2-3 0 1 2 3 )),
   PGA  => enumfield( 9, qw( 6.144V 4.096V 2.048V 1.024V 0.512V 0.256V )),
   MODE => enumfield( 8, qw( CONT SINGLE )),
   DR   => enumfield( 5, qw( 8 16 32 64 128 250 475 860 )),
   COMP_MODE => enumfield(4, qw( TRAD WINDOW )),
   COMP_POL  => enumfield(3, qw( LOW HIGH )),
   COMP_LAT  => boolfield(2),
   COMP_QUE  => enumfield(0, qw( 1 2 4 DIS ));

sub read_config
{
   my $self = shift;

   $self->cached_read_reg( REG_CONFIG, 1 )->then( sub {
      my ( $bytes ) = @_;
      Future->done( $self->{config} = { unpack_CONFIG( $bytes ) } );
   });
}

=head2 change_config

   $chip->change_config( %changes )->get

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

sub change_config
{
   my $self = shift;
   my %changes = @_;

   ( defined $self->{config} ? Future->done( $self->{config} ) :
         $self->read_config )->then( sub {
      my ( $config ) = @_;
      %$config = ( %$config, %changes );

      delete $self->{fullscale_f} if exists $changes{PGA};

      $self->cached_write_reg( REG_CONFIG, pack_CONFIG( %$config ) );
   });
}

=head2 trigger

   $chip->trigger->get

Set the C<OS> bit configuration bit, which will cause the chip to take a new
reading of the currently-selected input channel when in single-shot mode.

=cut

sub trigger
{
   my $self = shift;

   $self->read_config->then( sub {
      my ( $config ) = @_;
      # Not "cached" as OS is a volatile bit
      $self->write_reg( REG_CONFIG, pack_CONFIG( %$config, OS => 1 ) );
   });
}

=head2 read_adc

   $value = $chip->read_adc->get

Reads the most recent reading from the result register on the chip. This
method should be called after a suitable delay after the L</trigger> method
when in single-shot mode, or at any time when in continuous mode.

The reading is returned directly from the chip as a plain 16-bit signed
integer. To convert this into voltage use the L</read_adc_voltage> method.

=cut

sub read_adc
{
   my $self = shift;

   $self->read_reg( REG_RESULT, 1 )->then( sub {
      my ( $bytes ) = @_;
      Future->done( unpack "S>", $bytes );
   });
}

sub _fullscale
{
   my $self = shift;

   return $self->{fullscale_f} ||=
      $self->read_config->then( sub {
         my ( $config ) = @_;
         Future->done( ( $config->{PGA} =~ m/(\d\.\d+)V/ )[0] );
      });
}

=head2 read_adc_voltage

   $voltage = $chip->read_adc_voltage->get

Reads the most recent reading as per L</read_adc> and converts it into a
voltage level by taking into account the current setting of the C<PGA>
configuration option to scale it.

=cut

sub read_adc_voltage
{
   my $self = shift;

   Future->needs_all( $self->_fullscale, $self->read_adc )->then( sub {
      my ( $fullscale, $reading ) = @_;

      Future->done( ( $reading * $fullscale ) / ( 1 << 15 ) );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
