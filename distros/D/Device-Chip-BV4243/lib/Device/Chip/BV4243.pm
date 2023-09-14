#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::BV4243 0.04;
class Device::Chip::BV4243
   :isa(Device::Chip);

use utf8;

use Future::AsyncAwait;

=encoding UTF-8

=head1 NAME

C<Device::Chip::BV4243> - chip driver for a F<BV4243>

=head1 SYNOPSIS

   use Device::Chip::BV4243;
   use Future::AsyncAwait;

   my $chip = Device::Chip::BV4243->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->lcd_reset;
   await $chip->lcd_string( "Hello, world!" );

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a F<ByVac>
F<BV4243> LCD/touchpad display module attached to a computer via an I²C
adapter.

The reader is presumed to be familiar with the general operation of this
module; the documention here will not attempt to explain or define
module-specific concpets or features, only the use of this module to access
them.

=cut

use constant PROTOCOL => "I2C";

use constant {
   CMD_CLEAR_KEYS   => 1,
   CMD_GET_N_KEYS   => 2,  # => u8 count
   CMD_GET_KEY      => 3,  # => u8 key
   CMD_FIND_KEY     => 4,  # u8 key => u8 pos
   CMD_GET_SCANCODE => 5,  # => u8 code
   CMD_BEEP         => 6,  # u8 msec
   CMD_READ_CHAN    => 10, # => u16 * 8
   CMD_READ_DELTA   => 11, # => u16 * 8
   CMD_EEPROM_RESET => 20,
   CMD_SLEEP        => 21,

   CMD_LCD_RESET     => 30,
   CMD_LCD_COMMAND   => 31, # u8 cmd
   CMD_LCD_DATA      => 32, # u8 data
   CMD_LCD_STRING    => 33, # strZ string
   CMD_LCD_SIGNON    => 35,
   CMD_LCD_BACKLIGHT => 36, # u8 * 3 rgb - range 0-10

   CMD_SYS_READ_EEPROM  => 0x90, # u8 addr => u8 val
   CMD_SYS_WRITE_EEPROM => 0x91, # u8 addr, u8 val

   CMD_RESET => 0x95,

   CMD_VERSION   => 0xA0, # => u16
   CMD_DEVICE_ID => 0xA1, # => u16
};

async method _command ( $cmd, $data = "", $readlen = 0 )
{
   if( $readlen ) {
      await $self->protocol->write_then_read( pack( "C a*", $cmd, $data ), $readlen );
   }
   else {
      await $self->protocol->write( pack( "C a*", $cmd, $data ) );
   }
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

async method mount ( $adapter, %params )
{
   await $self->SUPER::mount( $adapter, %params );

   await $self->protocol->configure(
      addr => 0x3C,

      # Chip seems to misbehave at 100kHz; run it at 50
      max_bitrate => 50E3,
   );

   return $self;
}

# Command wrappers

=head2 clear_keys

   await $chip->clear_keys;

Clears the keypad buffer.

=cut

async method clear_keys ()
{
   await $self->_command( CMD_CLEAR_KEYS );
}

=head2 get_keycount

   $count = await $chip->get_keycount;

Returns the number of keys waiting in the keypad buffer.

=cut

async method get_keycount ()
{
   return unpack "C", await $self->_command( CMD_GET_N_KEYS, "", 1 );
}

=head2 get_key

   $key = await $chip->get_key;

Returns the next key from the keypad buffer, or 0 if there are none.

=cut

async method get_key ()
{
   return unpack "C", await $self->_command( CMD_GET_KEY, "", 1 );
}

=head2 find_key

   $pos = await $chip->find_key( $key );

Returns the position in the key buffer of the given key, or 0 if is not there.

=cut

async method find_key ( $key )
{
   return unpack "C", await $self->_command( CMD_FIND_KEY, pack( "C", $key ), 1 );
}

=head2 get_scancode

   $code = await $chip->get_scancode;

Returns the scan value from the keypad scanning matrix. This will be 0 if no
key is being touched, or an integer value with at least two bits set if a key
is being held.

=cut

async method get_scancode ()
{
   return unpack "C", await $self->_command( CMD_GET_SCANCODE, "", 1 );
}

=head2 beep

   await $chip->beep( $msec );

Turns on the C<BELL> output line for the specified number of miliseconds.

=cut

async method beep ( $msec )
{
   await $self->_command( CMD_BEEP, pack( "C", $msec ) );
}

=head2 read_chan

   @channels = await $chip->read_chan;

Returns the raw touchpad sensor values as 8 16bit integers.

=cut

async method read_chan ()
{
   return unpack "(S>)8", await $self->_command( CMD_READ_CHAN, "", 16 );
}

=head2 read_delta

   @deltas = await $chip->read_delta;

Returns the touchpad sensor values minus the trigger value.

=cut

async method read_delta ()
{
   return unpack "(S>)8", await $self->_command( CMD_READ_DELTA, "", 16 );
}

=head2 sleep

   await $chip->sleep;

Puts the device into sleep mode. It stops scanning the keypad, but will still
respond to another command which will wake it up again.

=cut

async method sleep ()
{
   await $self->_command( CMD_SLEEP );
}

=head2 lcd_reset

   await $chip->lcd_reset;

Resets the LCD.

=cut

async method lcd_reset ()
{
   await $self->_command( CMD_LCD_RESET );
}

=head2 lcd_command

   await $chip->lcd_command( $cmd );

Sends a numeric command to the LCD controller.

=cut

async method lcd_command ( $cmd )
{
   await $self->_command( CMD_LCD_COMMAND, pack "C", $cmd );
}

=head2 lcd_data

   await $chip->lcd_data( $data );

Sends a byte of numerical data to the LCD controller.

=cut

async method lcd_data ( $data )
{
   await $self->_command( CMD_LCD_DATA, pack "C", $data );
}

=head2 lcd_string

   await $chip->lcd_string( $str );

Sends a string of data to the LCD controller. This is a more efficient version
of sending each byte of the string individually using L</lcd_data>.

=cut

async method lcd_string ( $str )
{
   await $self->_command( CMD_LCD_STRING, $str . "\0" );
}

=head2 lcd_signon

   await $chip->lcd_signon;

Displays the signon string stored the in EEPROM.

=cut

async method lcd_signon ()
{
   await $self->_command( CMD_LCD_SIGNON );
}

=head2 lcd_backlight

   await $chip->lcd_backlight( $red, $green, $blue );

Sets the level of each of the three backlight channels. Each must be a numeric
value between 0 and 10 (inclusive). For single-backlight displays, use the
C<$red> channel.

=cut

async method lcd_backlight ( $red, $green, $blue )
{
   # Clamp to 0..10
   $_ > 10 and $_ = 10 for $red, $green, $blue;

   await $self->_command( CMD_LCD_BACKLIGHT, pack "CCC", $red, $green, $blue )
}

=head2 reset

   $chip->reset

Resets the device.

=cut

async method reset ()
{
   await $self->_command( CMD_RESET );
}

=head2 device_id

   $id = await $chip->device_id;

Returns the device ID value as a 16 bit integer

=cut

async method device_id ()
{
   return unpack "S>", await $self->_command( CMD_DEVICE_ID, "", 2 );
}

=head2 version

   $id = await $chip->version;

Returns the device firmware version as a 16 bit integer

=cut

async method version ()
{
   return unpack "S>", await $self->_command( CMD_VERSION, "", 2 );
}

=head2 eeprom_reset

   await $chip->eeprom_reset;

Resets the configuration EEPROM back to default values.

=cut

async method eeprom_reset ()
{
   await $self->_command( CMD_EEPROM_RESET );
}

=head2 eeprom_read

   $val = await $chip->eeprom_read( $addr );

Reads a byte from the configuration EEPROM.

=cut

async method eeprom_read ( $addr )
{
   return unpack "C", await $self->_command( CMD_SYS_READ_EEPROM, pack( "C", $addr ), 1 );
}

=head2 eeprom_write

   await $chip->eeprom_write( $addr, $val );

Writes a byte to the configuration EEPROM.

=cut

async method eeprom_write ( $addr, $val )
{
   await $self->_command( CMD_SYS_WRITE_EEPROM, pack( "C C", $addr, $val ) );
}

=head1 SEE ALSO

L<http://www.pichips.co.uk/index.php/BV4243>

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
