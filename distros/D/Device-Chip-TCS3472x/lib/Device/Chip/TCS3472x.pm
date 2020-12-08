#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad;

package Device::Chip::TCS3472x 0.02;
class Device::Chip::TCS3472x
   extends Device::Chip;

use Carp;

use Future;
use Future::AsyncAwait;

use Data::Bitfield 0.03 qw( bitfield boolfield intfield enumfield );

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::TCS3472x> - chip driver for F<TCS3472x>-family

=head1 SYNOPSIS

   use Device::Chip::TCS3472x;
   use Future::AsyncAwait;

   my $chip = Device::Chip::TCS3472x->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   # Power on and enable ADCs
   await $chip->change_config(
      PON => 1,
      AEN => 1,
   );

   # At default config, first sensor reading is available after
   # 620 msec
   sleep 0.620;

   my ( $clear, $red, $green, $blue ) = await $chip->read_crgb;
   print "Red=$red Green=$green Blue=$blue\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a
F<TASOC Inc.> F<TCS3472x>-family RGB light sensor chip.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 led

Optional name of the GPIO line attached to the LED control pin common to many
breakout boards. This is used by the L</set_led> method.

=cut

has $_led_pin;

method mount ( $adapter, %params )
{
   $_led_pin = delete $params{led} if exists $params{led};

   return $self->SUPER::mount( @_ );
}

sub I2C_options
{
   return (
      addr        => 0x29,
      max_bitrate => 400E3,
   );
}

use constant {
   COMMAND => 0x80,
   COMMAND_AUTOINC => (1 << 5),

   REG_ENABLE  => 0x00,
   REG_ATIME   => 0x01,
   REG_WTIME   => 0x03,
   REG_AILT    => 0x04, # 16bit LE
   REG_AIHT    => 0x06, # 16bit LE
   REG_PERS    => 0x0C,
   REG_CONFIG  => 0x0D,
   REG_CONTROL => 0x0F,
   REG_ID      => 0x12,

   REG_CDATA => 0x14, # 16bit LE
};

bitfield { format => "bytes-LE" }, CONFIG =>
   # REG_ENABLE
   AIEN => boolfield( 0*8 + 4 ),
   WEN  => boolfield( 0*8 + 3 ),
   AEN  => boolfield( 0*8 + 1 ),
   PON  => boolfield( 0*8 + 0 ),
   # REG_ATIME
   ATIME => intfield( 1*8, 8 ),
   # REG_WTIME
   WTIME => intfield( 2*8, 8 ),
   # REG_AILT 3,4 + REG_AIHT 5,6 TODO
   # REG_PERS
   APERS => enumfield( 7*8 + 0,
      qw( EVERY 1 2 3 5 10 15 20 25 30 35 40 45 50 55 60 ) ),
   # REG_CONFIG
   WLONG => boolfield( 8*8 + 1 ),
   # REG_CONTROL
   AGAIN => enumfield( 9*8 + 0, qw( 1 4 16 60 ) ),
   ;

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

async method read_reg ( $addr, $len = 1 )
{
   return await $self->protocol->write_then_read(
      pack( "C", COMMAND | COMMAND_AUTOINC | ( $addr & 0x1F ) ), $len
   );
}

has @_regcache;

async method cached_read_reg ( $addr, $len = 1 )
{
   my $ret = "";
   my $end = $addr + $len;

   while( $addr < $end ) {
      if( defined $_regcache[$addr] ) {
         $ret .= $_regcache[$addr++];
         next;
      }

      $len = 1;
      $len++ while $addr+$len < $end and !defined $_regcache[$addr + $len];

      my $val = await $self->read_reg( $addr, $len );

      $ret .= $val;
      $_regcache[$addr++] = substr( $val, 0, 1, "" ) while length $val;
   }

   return $ret;
}

async method cached_update_reg ( $addr, $val )
{
   while( length $val ) {
      $addr++, substr( $val, 0, 1, "" ), next if
         defined $_regcache[$addr] and $_regcache[$addr] eq substr( $val, 0, 1 );

      my $len = 1;
      # TODO: Coäless longer writes

      await $self->protocol->write(
         pack( "C a*", COMMAND | COMMAND_AUTOINC | ( $addr & 0x1F ),
            substr( $val, 0, $len )
         )
      );

      $_regcache[$addr++] = substr( $val, 0, 1, "" ), $len--
         while $len;
   }
}

=head2 read_id

   $id = await $chip->read_id;

Returns a 2-character string from the ID register. The expected value will
depend on the type of chip

   "44"  # TCS34721 or TCS34725
   "4D"  # TCS34723 or TCS34727

=cut

async method read_id ()
{
   return sprintf "%02X", unpack "C", await $self->read_reg( REG_ID );
}

=head2 read_config

   $config = await $chip->read_config;

Returns a hash reference containing the current chip configuration.

   AEN   => bool
   AIEN  => bool
   AGAIN => 1 | 4 | 16 | 60
   APERS => "EVERY" | int
   ATIME => int
   PON   => bool
   WEN   => bool
   WLONG => bool
   WTIME => int

The returned value also contains some lowercase-named synthesized fields,
containing helper values derived from the chip config. These keys are not
supported by L</change_config>.

   atime_cycles => int   # number of integration cycles implied by ATIME
   atime_msec   => num   # total integration time implied by ATIME

   wtime_cycles => int   # number of wait cycles implied by WTIME
   wtime_msec   => num   # total wait time implied by WTIME and WLONG

=cut

async method read_config ()
{
   my $config = join "", await Future->needs_all(
      $self->cached_read_reg( REG_ENABLE,  2 ), # + REG_ATIME
      $self->cached_read_reg( REG_WTIME,   5 ), # + REG_AILT + REG_AIHT
      $self->cached_read_reg( REG_PERS,    2 ), # + REG_CONFIG
      $self->cached_read_reg( REG_CONTROL, 1 ),
   );

   my %config = unpack_CONFIG( $config );

   # Some derived helper fields
   $config{atime_cycles} = 256 - $config{ATIME};
   $config{atime_msec}   = $config{atime_cycles} * 2.4;

   $config{wtime_cycles} = 256 - $config{WTIME};
   $config{wtime_msec}   = $config{wtime_cycles} * 2.4;
   $config{wtime_msec} *= 12 if $config{WLONG};

   return \%config;
}

=head2 change_config

   await $chip->change_config( %changes )

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

async method change_config ( %changes )
{
   my %config = (
      ( await $self->read_config )->%*,
      %changes,
   );

   # TODO: Accept changes in derived fields
   m/^[a-z]/ and delete $config{$_} for keys %config;

   my $val = pack_CONFIG( %config );

   await Future->needs_all(
      $self->cached_update_reg( REG_ENABLE,  substr( $val, 0, 2, "" ) ), # + REG_ATIME
      $self->cached_update_reg( REG_WTIME,   substr( $val, 0, 5, "" ) ), # + REG_AILT + REG_AIHT
      $self->cached_update_reg( REG_PERS,    substr( $val, 0, 2, "" ) ), # + REG_CONFIG
      $self->cached_update_reg( REG_CONTROL, substr( $val, 0, 1, "" ) ),
   );
}

=head2 read_crgb

   ( $clear, $red, $green, $blue ) = await $chip->read_crgb

Returns the result of the most recent colour acquisition.

=cut

async method read_crgb ()
{
   return unpack "S< S< S< S<", await $self->read_reg( REG_CDATA, 8 );
}

=head2 set_led

   await $chip->set_led( $on );

If the C<led> mount parameter was specified, this method acts as a proxy for
the named GPIO line, setting it high or low to control the LED.

While not a feature of the F<TCS3472x> sensor chip itself, this is common to
many breakout boards, so is provided here as a convenience.

=cut

async method set_led ( $on )
{
   defined $_led_pin or
      croak "Cannot ->set_led unless 'led' mount parameter is defined";

   await $self->protocol->write_gpios( { $_led_pin => $on } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
