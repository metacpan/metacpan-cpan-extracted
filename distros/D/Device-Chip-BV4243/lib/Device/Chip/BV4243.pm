#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Device::Chip::BV4243;

use strict;
use warnings;
use base qw( Device::Chip );

use utf8;

our $VERSION = '0.01';

=encoding UTF-8

=head1 NAME

C<Device::Chip::BV4243> - chip driver for a F<BV4243>

=head1 SYNOPSIS

 use Device::Chip::BV4243;

 my $chip = Device::Chip::BV4243->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 $chip->lcd_reset->get;
 $chip->lcd_string( "Hello, world!" )->get;

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

sub _command
{
   my $self = shift;
   my ( $cmd, $data, $readlen ) = @_;

   if( $readlen ) {
      $self->protocol->write_then_read( pack( "C a*", $cmd, $data // "" ), $readlen );
   }
   else {
      $self->protocol->write( pack( "C a*", $cmd, $data // "" ) );
   }
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub mount
{
   my $self = shift;
   $self->SUPER::mount( @_ )->then( sub {
      $self->protocol->configure(
         addr => 0x3C,

         # Chip seems to misbehave at 100kHz; run it at 50
         max_bitrate => 50E3,
      )
   })
}

# Command wrappers

=head2 clear_keys

   $chip->clear_keys->get

Clears the keypad buffer.

=cut

sub clear_keys
{
   my $self = shift;
   $self->_command( CMD_CLEAR_KEYS );
}

=head2 get_keycount

   $count = $chip->get_keycount->get

Returns the number of keys waiting in the keypad buffer.

=cut

sub get_keycount
{
   my $self = shift;
   $self->_command( CMD_GET_N_KEYS, "", 1 )
      ->transform( done => sub { unpack "C", $_[0] } );
}

=head2 get_key

   $key = $chip->get_key->get

Returns the next key from the keypad buffer, or 0 if there are none.

=cut

sub get_key
{
   my $self = shift;
   $self->_command( CMD_GET_KEY, "", 1 )
      ->transform( done => sub { unpack "C", $_[0] } );
}

=head2 find_key

   $pos = $chip->find_key( $key )->get

Returns the position in the key buffer of the given key, or 0 if is not there.

=cut

sub find_key
{
   my $self = shift;
   my ( $key ) = @_;
   $self->_command( CMD_FIND_KEY, pack( "C", $key ), 1 )
      ->transform( done => sub { unpack "C", $_[0] } );
}

=head2 get_scancode

   $code = $chip->get_scancode->get

Returns the scan value from the keypad scanning matrix. This will be 0 if no
key is being touched, or an integer value with at least two bits set if a key
is being held.

=cut

sub get_scancode
{
   my $self = shift;
   $self->_command( CMD_GET_SCANCODE, "", 1 )
      ->transform( done => sub { unpack "C", $_[0] } );
}

=head2 beep

   $chip->beep( $msec )->get

Turns on the C<BELL> output line for the specified number of miliseconds.

=cut

sub beep
{
   my $self = shift;
   my ( $msec ) = @_;
   $self->_command( CMD_BEEP, pack( "C", $msec ) );
}

=head2 read_chan

   @channels = $chip->read_chan->get

Returns the raw touchpad sensor values as 8 16bit integers.

=cut

sub read_chan
{
   my $self = shift;
   $self->_command( CMD_READ_CHAN, "", 16 )
      ->transform( done => sub { unpack( "(S>)8", $_[0] ) } );
}

=head2 read_delta

   @deltas = $chip->read_delta->get

Returns the touchpad sensor values minus the trigger value.

=cut

sub read_delta
{
   my $self = shift;
   $self->_command( CMD_READ_DELTA, "", 16 )
      ->transform( done => sub { unpack( "(S>)8", $_[0] ) } );
}

=head2 sleep

   $chip->sleep->get

Puts the device into sleep mode. It stops scanning the keypad, but will still
respond to another command which will wake it up again.

=cut

sub sleep
{
   my $self = shift;
   $self->_command( CMD_SLEEP );
}

=head2 lcd_reset

   $chip->lcd_reset->get

Resets the LCD.

=cut

sub lcd_reset
{
   my $self = shift;
   $self->_command( CMD_LCD_RESET );
}

=head2 lcd_command

   $chip->lcd_command( $cmd )->get;

Sends a numeric command to the LCD controller.

=cut

sub lcd_command
{
   my $self = shift;
   my ( $cmd ) = @_;
   $self->_command( CMD_LCD_COMMAND, pack "C", $cmd );
}

=head2 lcd_data

   $chip->lcd_data( $data )->get

Sends a byte of numerical data to the LCD controller.

=cut

sub lcd_data
{
   my $self = shift;
   my ( $data ) = @_;
   $self->_command( CMD_LCD_DATA, pack "C", $data );
}

=head2 lcd_string

   $chip->lcd_string( $str )->get

Sends a string of data to the LCD controller. This is a more efficient version
of sending each byte of the string individually using L</lcd_data>.

=cut

sub lcd_string
{
   my $self = shift;
   my ( $str ) = @_;
   $self->_command( CMD_LCD_STRING, $str . "\0" );
}

=head2 lcd_signon

   $chip->lcd_signon->get

Displays the signon string stored the in EEPROM.

=cut

sub lcd_signon
{
   my $self = shift;
   $self->_command( CMD_LCD_SIGNON );
}

=head2 lcd_backlight

   $chip->lcd_backlight( $red, $green, $blue )->get

Sets the level of each of the three backlight channels. Each must be a numeric
value between 0 and 10 (inclusive). For single-backlight displays, use the
C<$red> channel.

=cut

sub lcd_backlight
{
   my $self = shift;
   my ( $red, $green, $blue ) = @_;

   # Clamp to 0..10
   $_ > 10 and $_ = 10 for $red, $green, $blue;
   $self->_command( CMD_LCD_BACKLIGHT, pack "CCC", $red, $green, $blue )
}

=head2 reset

   $chip->reset

Resets the device.

=cut

sub reset
{
   my $self = shift;
   $self->_command( CMD_RESET );
}

=head2 device_id

   $id = $chip->device_id->get

Returns the device ID value as a 16 bit integer

=cut

sub device_id
{
   my $self = shift;
   $self->_command( CMD_DEVICE_ID, "", 2 )
      ->transform( done => sub { unpack "S>", $_[0] } );
}

=head2 version

   $id = $chip->version->get

Returns the device firmware version as a 16 bit integer

=cut

sub version
{
   my $self = shift;
   $self->_command( CMD_VERSION, "", 2 )
      ->transform( done => sub { unpack "S>", $_[0] } );
}

=head2 eeprom_reset

   $chip->eeprom_reset->get

Resets the configuration EEPROM back to default values.

=cut

sub eeprom_reset
{
   my $self = shift;
   $self->_command( CMD_EEPROM_RESET );
}

=head2 eeprom_read

   $val = $chip->eeprom_read( $addr )->get

Reads a byte from the configuration EEPROM.

=cut

sub eeprom_read
{
   my $self = shift;
   my ( $addr ) = @_;
   $self->_command( CMD_SYS_READ_EEPROM, pack( "C", $addr ), 1 )
      ->transform( done => sub { unpack "C", $_[0] } );
}

=head2 eeprom_write

   $chip->eeprom_write( $addr, $val )->get

Writes a byte to the configuration EEPROM.

=cut

sub eeprom_write
{
   my $self = shift;
   my ( $addr, $val ) = @_;
   $self->_command( CMD_SYS_WRITE_EEPROM, pack( "C C", $addr, $val ) );
}

=head1 SEE ALSO

L<http://www.pichips.co.uk/index.php/BV4243>

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
