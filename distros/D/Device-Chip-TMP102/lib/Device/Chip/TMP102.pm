#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#

package Device::Chip::TMP102;

use strict;
use warnings;
use 5.010;
use base qw( Device::Chip::Base::RegisteredI2C );
Device::Chip::Base::RegisteredI2C->VERSION('0.10');

use constant REG_DATA_SIZE => 16;

use constant DEBUG => 0;

use utf8;

our $VERSION = '0.02';

use Data::Bitfield qw( bitfield boolfield enumfield );

=encoding UTF-8

=head1 NAME

C<Device::Chip::TMP102> - chip driver for a F<TMP102>

=head1 SYNOPSIS

 use Device::Chip::TMP102;

 my $chip = Device::Chip::TMP102->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 printf "Temperature is %2.2f C\n", $chip->read_temp->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<TMP102> attached to a computer via an I²C adapter.

Not all of the chip's capabilities are currently accessible through this driver.  Extended mode is supported.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

sub I2C_options {
    my $self   = shift;
    my %params = @_;

    my $addr = delete $params{addr} // 0x40;
    $addr = oct $addr if $addr =~ m/^0/;

    return (
        %params,    # this needs to fixed with resolution of 127570
        addr        => $addr,
        max_bitrate => 400E3,
    );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

use constant {
    REG_TEMP   => 0x00,    # R
    REG_CONFIG => 0x01,    # R/W
    REG_T_LOW  => 0x02,    # R/W
    REG_T_HIGH => 0x03,    # R/W
};

bitfield CONFIG =>
    SD  => boolfield(0),
    TM  => boolfield(1),
    POL => boolfield(2),
    F   => enumfield(3, qw( 1 2 4 6 )),
    R0  => boolfield(5),   # R
    R1  => boolfield(6),   # R
    OS  => boolfield(7),
    EM  => boolfield(12),
    AL  => boolfield(13),
    CR  => enumfield(14, qw( 0.25Hz 1Hz 4Hz 8hz ));

=head2 read_config

   $config = $chip->read_config->get

Reads and returns the current chip configuration as a C<HASH> reference.

   SD  => 0 | 1
   TM  => 0 | 1
   POL => 0 | 1
   F   => "1" | "2" | "4" | "6"
   R0  => 0 | 1  (read only)
   R1  => 0 | 1  (read only)
   OS  => 0 | 1
   EM  => 0 | 1
   AL  => 0 | 1
   CR  => "0.25Hz" | "1Hz" | "4Hz" | "8Hz"

=cut

sub read_config
{
    my $self = shift;

    $self->cached_read_reg( REG_CONFIG, 1 )->then( sub {
	my ( $bytes ) = @_;
	Future->done( $self->{config} = { unpack_CONFIG( unpack "S<", $bytes ) } );
    });
}

=head2 change_config

   $chip->change_config( %config )->get

Changes the configuration. Any field names not mentioned will be preserved.

=cut

sub change_config
{
    my $self = shift;
    my %changes = @_;

    ( defined $self->{config} ? Future->done( $self->{config} ) :
      $self->read_config )->then( sub {
	  my %config = ( %{ $_[0] }, %changes );

	  undef $self->{config}; # invalidate the cache
	  $self->write_reg( REG_CONFIG, pack "S<", pack_CONFIG( %config ) );
				  });
}

=head2 read_temp

   $temp = $chip->read_temp->get

Returns the temperature in degrees Celsius.

=cut

sub read_temp {
    my $self = shift;

    Future->needs_all(
        $self->read_reg( REG_TEMP, 1 ),
        ( $self->{config} ? Future->done( $self->{config} ) :
	                    $self->read_config ),
    )->then( sub {
        my ( $value, $config ) = @_;

        Future->done($self->_bytes_to_temp(unpack "s<", $value));
    });
}

=head2 write_temp_low

   $chip->write_temp_low( $temp )->get

Changes the low temperature threshold in degrees Celsius.

=cut

sub write_temp_low {
    my ($self, $temp) = @_;

    $self->write_reg( REG_T_LOW, pack "s>", $self->_temp_to_bytes($temp) );
}

=head2 read_temp_low

   $temp = $chip->read_temp_low->get

Returns the low temperature threshold in degrees Celsius.

=cut

sub read_temp_low {
    my $self = shift;

    Future->needs_all(
        $self->read_reg( REG_T_LOW, 1 ),
        ( $self->{config} ? Future->done( $self->{config} ) :
	                    $self->read_config ),
    )->then( sub {
        my ( $value, $config ) = @_;

        Future->done($self->_bytes_to_temp(unpack "s<", $value));
    });
}

=head2 write_temp_high

   $chip->write_temp_high( $temp )->get

Changes the high temperature threshold in degrees Celsius.

=cut

sub write_temp_high {
    my ($self, $temp) = @_;

    $self->write_reg( REG_T_HIGH, pack "s>", $self->_temp_to_bytes($temp) );
}

=head2 read_temp_high

   $temp = $chip->read_temp_high->get

Returns the high temperature threshold in degrees Celsius.

=cut

sub read_temp_high {
    my $self = shift;

    Future->needs_all(
        $self->read_reg( REG_T_HIGH, 1 ),
        ( $self->{config} ? Future->done( $self->{config} ) :
	                    $self->read_config ),
    )->then( sub {
        my ( $value, $config ) = @_;

        Future->done($self->_bytes_to_temp(unpack "s<", $value));
    });
}

sub _bytes_to_temp {
    my ($self, $value) = @_;

    my $lo = ( $value & 0xff00 );
    $lo = $lo >> 8;

    my $hi = $value & 0x00ff;

    my $hilo = $hi*256+$lo;   # data is read little endian so swap bytes

    printf( "res <  : %04x\n", $value ) if DEBUG;
    printf( "hi:      %02x\n", $hi ) if DEBUG;
    printf( "lo:      %02x\n", $lo ) if DEBUG;
    printf( "res >  : %04x\n", $hilo) if DEBUG;

    my $shift = 4;
    if ($self->{config}{EM}) { $shift = 3 }

    my $t = $hilo >> $shift;

    if (($hi | 0x7F) == 0xFF) { # negative temperature
	$t = ~$t +1;
	$t &= 0xFFF;
	$t *= -1;
    }

    return $t * 0.0625;
}

sub _temp_to_bytes {
    my ($self, $temp) = @_;

    my $shift = 4;
    if ($self->{config}{EM}) { $shift = 3 }

    my $t = int(abs($temp)/0.0625) << $shift;

    if ($temp < 0) {
        $t = ~$t + 1;
	$t &= 0xFFFF;
    }
    return $t
}

0x55AA;
