#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#

package Device::Chip::ADT7470;

use strict;
use warnings;
use 5.010;
use base qw( Device::Chip::Base::RegisteredI2C );
Device::Chip::Base::RegisteredI2C->VERSION('0.10');

use constant REG_DATA_SIZE => 8;

use utf8;

our $VERSION = '0.03';

use Carp;
use Data::Bitfield qw( bitfield boolfield );

use constant { STALLED => 0xFFFF };

=encoding UTF-8

=head1 NAME

C<Device::Chip::ADT7470> - chip driver for an F<ADT7470>

=head1 SYNOPSIS

 use Device::Chip::ADT7470;

 my $chip = Device::Chip::ADT7470->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 printf "Current fan 1 speed is %d rpm\n", $chip->read_fan_rpm( 1 )->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Analog Devices> F<ADT7470> attached to a computer via an I²C adapter.

Only a subset of the chip's capabilities are currently accessible through this driver.

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
    REG_TACH => {
	FAN1 => {
	    LOWBYTE  => 0x2A,
	    HIGHBYTE => 0x2B
	},
	FAN2 => {
	    LOWBYTE  => 0x2C,
	    HIGHBYTE => 0x2D
	},
	FAN3 => {
	    LOWBYTE  => 0x2E,
	    HIGHBYTE => 0x2F
	},
	FAN4 => {
	    LOWBYTE  => 0x30,
	    HIGHBYTE => 0x31
	}
    },
    REG_DUTY => {
        FAN1 => 0x32,
        FAN2 => 0x33,
        FAN3 => 0x34,
        FAN4 => 0x35
    },
    REG_DEVICEID  => 0x3D,    # R
    REG_COMPANYID => 0x3E,    # R
    REG_REVNUMBER => 0x3F,    # R
    REG_CONFIG1   => 0x40,    # R/W
};

bitfield { format => "bytes-BE" }, CONFIG1 =>
  STRT      => boolfield(0),
  TODIS     => boolfield(3),
  LOCK      => boolfield(4),
  FST_TCH   => boolfield(5),
  HF_LF     => boolfield(6),
  T05_STB   => boolfield(7);

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference of the contents of the user register.

   STRT    => 0 | 1
   TODIS   => 0 | 1
   LOCK    => 0 | 1  (power cycle to unlock)
   FST_TCH => 0 | 1
   HF_LF   => 0 | 1
   T05_STB => 0 | 1

=cut

sub read_config {
    my $self = shift;

    $self->cached_read_reg( REG_CONFIG1, 1 )->then(
        sub {
            my ($bytes) = @_;
            Future->done( $self->{config} = { unpack_CONFIG1($bytes) } );
        }
    );
}

=head2 change_config

   $chip->change_config( %config )->get

Changes the configuration. Any field names not mentioned will be preserved.

=cut

sub change_config {
    my $self    = shift;
    my %changes = @_;

    (
        defined $self->{config}
        ? Future->done( $self->{config} )
        : $self->read_config
      )->then(
        sub {
            my %config = ( %{ $_[0] }, %changes );

            undef $self->{config};    # invalidate the cache
            $self->write_reg( REG_CONFIG1, pack_CONFIG1(%config) );
        }
      );
}

=head2 read_duty

   $duty = $chip->read_duty( $fan )->get

Returns the pwm duty cycle for the specified fan (1-4).

=cut

sub read_duty {
    my ( $self, $fan ) = @_;

    $fan = $self->_format_fan($fan);

    $self->read_reg( REG_DUTY->{"$fan"}, 1 )->then(
        sub {
            my ($duty) = unpack "C", $_[0];

            Future->done($duty);
        }
    );
}

=head2 read_duty_percent

   $duty = $chip->read_duty_percent( $fan )->get

Returns the pwm duty cycle as a percentage for the specified fan (1-4).

=cut

sub read_duty_percent {
    my ( $self, $fan ) = @_;

    $self->read_duty($fan)->then(
        sub {
            Future->done( int( $_[0] / 255 * 100 + 0.5) );
        }
    );
}

=head2 write_duty

   $duty = $chip->write_duty( $fan, $duty )->get

Writes the pwm duty cycle for the specified fan.

=cut

sub write_duty {
    my ( $self, $fan, $duty ) = @_;

    $fan = $self->_format_fan($fan);

    if ( $duty < 0 )   { $duty = 0 }
    if ( $duty > 255 ) { $duty = 255 }

    $self->write_reg( REG_DUTY->{$fan}, pack "C", $duty );
}

=head2 write_duty_percent

   $duty = $chip->write_duty_percent( $fan, $percent )->get

Writes the pwm duty cycle as a percentage for the specified fan.

=cut

sub write_duty_percent {
    my ( $self, $fan, $percent ) = @_;

    $self->write_duty( $fan, $percent / 100 * 255 );
}

=head2 read_fan_rpm

   $rpm = $chip->read_fan_rpm( $fan )->get

Read the fan rpm for the specified fan.

=cut

sub read_fan_rpm {
    my ( $self, $fan ) = @_;

    $fan = $self->_format_fan($fan);

    Future->needs_all(
	$self->read_reg( REG_TACH->{$fan}->{LOWBYTE}, 1 ),
	$self->read_reg( REG_TACH->{$fan}->{HIGHBYTE}, 1 ),
	)->then( sub {
	    my ( $lo, $hi ) = @_;
	    my $result = unpack "S<", $lo . $hi;

	    my $rpm = ($result != STALLED) ? int((90000*60)/$result) : 0;

	    Future->done($rpm);
	}
    );

}

sub _format_fan {
    my ( $self, $fan ) = @_;

    grep( /^$fan$/, qw(1 2 3 4) ) or croak 'Fan must be 1-4';

    return sprintf( 'FAN%d', $fan );
}

0x55AA;
