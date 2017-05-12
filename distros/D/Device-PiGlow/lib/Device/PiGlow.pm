package Device::PiGlow;

use strict;
use warnings;

our $VERSION = '1.1';

use Moose;


use Device::SMBus;


# These are all the register numbers defined by the device
use constant CMD_ENABLE_OUTPUT => 0x00;
use constant CMD_ENABLE_LEDS => 0x13;
use constant CMD_ENABLE_LEDS_1 => 0x13;
use constant CMD_ENABLE_LEDS_2 => 0x14;
use constant CMD_ENABLE_LEDS_3 => 0x15;
use constant CMD_SET_PWM_VALUES => 0x01;
use constant CMD_SET_PWM_VALUE_1 => 0x01;
use constant CMD_SET_PWM_VALUE_2 => 0x02;
use constant CMD_SET_PWM_VALUE_3 => 0x03;
use constant CMD_SET_PWM_VALUE_4 => 0x04;
use constant CMD_SET_PWM_VALUE_5 => 0x05;
use constant CMD_SET_PWM_VALUE_6 => 0x06;
use constant CMD_SET_PWM_VALUE_7 => 0x07;
use constant CMD_SET_PWM_VALUE_8 => 0x08;
use constant CMD_SET_PWM_VALUE_9 => 0x09;
use constant CMD_SET_PWM_VALUE_10 => 0x0A;
use constant CMD_SET_PWM_VALUE_11 => 0x0B;
use constant CMD_SET_PWM_VALUE_12 => 0x0C;
use constant CMD_SET_PWM_VALUE_13 => 0x0D;
use constant CMD_SET_PWM_VALUE_14 => 0x0E;
use constant CMD_SET_PWM_VALUE_15 => 0x0F;
use constant CMD_SET_PWM_VALUE_16 => 0x10;
use constant CMD_SET_PWM_VALUE_17 => 0x11;
use constant CMD_SET_PWM_VALUE_18 => 0x12;
use constant CMD_UPDATE => 0x16;
use constant CMD_RESET => 0x17;
=head1 NAME

Device::PiGlow - Interface to the PiGlow board using i2c

=head1 SYNOPSIS

    use Device::PiGlow;

    my $pg = Device::PiGlow->new();

    my $values = [0x01,0x02,0x04,0x08,0x10,0x18,0x20,0x30,0x40,0x50,0x60,0x70,0x80,0x90,0xA0,0xC0,0xE0,0xFF];

    $pg->enable_output();
    $pg->enable_all_leds();

    $pg->write_all_leds($values);
    sleep 10;
    $pg->reset();


See the L<examples> directory for more ways of using this.

=head1 DESCRIPTION

The PiGlow from Pimoroni (http://shop.pimoroni.com/products/piglow) is 
a small board that plugs in to the Raspberry PI's GPIO header 
with 18 LEDs on that can be addressed individually via i2c.

This module uses L<Device::SMBus> to abstract the interface to the device
so that it can be controlled from a Perl programme.

It is assumed that you have installed the OS packages required to make
i2c work and have configured and tested the i2c appropriately.  The only
difference that seems to affect the PiGlow device is that it only seems
to be reported by C<i2cdetect> if you use the "quick write" probe flag:

   sudo i2cdetect -y -q 1

(assuming you have a Rev B. Pi - if not you should supply 0 instead of 1.) 
I have no way of knowing the compatibility of the "quick write" with any
other devices you may have plugged in to the Pi, so I wouldn't recommend
doing this with any other devices unless you know that they won't be adversely
affected by "quick write".  The PiGlow has a fixed address anyway so the
information isn't that useful.

=head2 METHODS

=over 4

=item new

The constructor.  This takes two optional attributes which are passed on
directly to the L<Device::SMBus> constructor:

=over 4

=item I2CBusDevicePath

This sets the device path, it defaults to /dev/i2c-1 (assuming a newer
Raspberry PI,) You will want to set this if you are using an older PI or
an OS that creates a different device.

=cut

has I2CBusDevicePath =>	(
			   is  => 'rw',
                           isa => 'Str',
                           default => '/dev/i2c-1',
			);

=item I2CDeviceAddress

This sets the i2c device address,  this defaults to 0x54.  Unless you have
somehow altered the address you shouldn't need to change this.

=cut

has I2CDeviceAddress => (
			   is  => 'rw',
                           isa => 'Num',
                           default => 0x54,
			);

=back

=item device_smbus

This is the L<Device::SMBus> object we will be using to interact with i2c.
It will be initialised with the attributes described above.  You may want
this if you need to do something to the PiGlow I haven't thought of.

=cut

has device_smbus  => (
                        is => 'ro',
                        isa => 'Device::SMBus',
                        lazy => 1,
                        builder => '_get_device_smbus',
                        handles => {
                                     i2c_file => 'I2CBusFilenumber',
                                     _write_byte => 'writeByteData',
                                   },
		     );

sub _get_device_smbus
{
   my ( $self ) = @_;

   my $smbus = Device::SMBus->new(
				    I2CBusDevicePath => $self->I2CBusDevicePath,
                                    I2CDeviceAddress => $self->I2CDeviceAddress
                                 );
   return $smbus;
}

=item update

This updates the values set to the LED registers to the LEDs and changes
the display.

=cut

sub update
{
   my ( $self ) = @_;
   
   return $self->_write_byte(CMD_UPDATE, 0xFF);
}

=item enable_output

This sets the state of the device to active.  

=cut

sub enable_output
{
   my ( $self ) = @_;
   return $self->_write_byte(CMD_ENABLE_OUTPUT, 0x01);
}

has '_led_bank_enable_registers' => (
                                       is  => 'ro',
                                       isa => 'ArrayRef',
                                       lazy => 1,
                                       auto_deref => 1,
                                       default  => sub {
                                          return [
                                                   CMD_ENABLE_LEDS_1,
                                                   CMD_ENABLE_LEDS_2,
                                                   CMD_ENABLE_LEDS_3,
                                                 ];
                                       },
                                    );

=item enable_all_leds

This turns on all three banks of LEDs.

=cut

sub enable_all_leds
{
   my ( $self ) = @_;
   return $self->write_block_data(CMD_ENABLE_LEDS, [0xFF, 0xFF, 0xFF]);
}

=item write_all_leds

This writes the PWM values supplied as an Array Reference and immediately
calls C<update> to apply the values to the LEDs.

The array must be exactly 18 elements long.

The optional second argument will cause the gamma correction to be applied
if the value is true.

=cut

sub write_all_leds
{
   my ( $self, $values, $fix ) = @_;

   if ( @{$values} == 18 )
   {
       if ( $fix )
       {
          $values = $self->gamma_fix_values($values);
       }
       $self->write_block_data(CMD_SET_PWM_VALUES, $values);
       $self->update();
   }
}

=item all_off

This is convenience to turn off (set to brightness 0) all the LEDs at
once.  It calls C<update> immediately.

=cut

sub all_off
{
   my ( $self ) = @_;

   my $vals = [];
   @{$vals} = (0) x 18;

   $self->write_all_leds($vals);
}

=item set_leds

This sets the leds specified in the array reference in the first argument
( values 0 - 17 to index the LEDs ) all to the single value specified.

Gamma adjustment is applied. 

This does not call update, this should be done afterwards in order to
update the LED values.

=cut

sub set_leds
{
    my ( $self, $leds, $value ) = @_;

    if (defined $leds && ( $value >= 0 && $value <= 255 ))
    {
        $value = $self->map_gamma($value);
        foreach my $led ( @{$leds} )
        {
	   if ( $led >= 0 && $led <= 17 )
           {
              $self->_write_byte($self->get_led_register($led), $value);
           }
        }
    }
}

=item led_table

This provides a mapping between the logical order of the leds (indexed 
0 - 17 ) to the registers that control them.

=cut

has led_table => (
		    is =>  'ro',
                    isa => 'ArrayRef',
                    traits => [qw(Array)],
                    handles => {
                      get_led_register => 'get',
                    },
                    auto_deref	=> 1,
                    lazy	=> 1,
 		    builder	=> '_get_led_table',
                 );

# "0x07", "0x08", "0x09", "0x06", "0x05", "0x0A", "0x12", "0x11",
# "0x10", "0x0E", "0x0C", "0x0B", "0x01", "0x02", "0x03", "0x04", "0x0F", "0x0D"
sub _get_led_table
{
   my ( $self ) = @_;

   return [
             CMD_SET_PWM_VALUE_7,
             CMD_SET_PWM_VALUE_8,
             CMD_SET_PWM_VALUE_9,
             CMD_SET_PWM_VALUE_6,
             CMD_SET_PWM_VALUE_5,
             CMD_SET_PWM_VALUE_10,
             CMD_SET_PWM_VALUE_18,
             CMD_SET_PWM_VALUE_17,
             CMD_SET_PWM_VALUE_16,
             CMD_SET_PWM_VALUE_14,
             CMD_SET_PWM_VALUE_12,
             CMD_SET_PWM_VALUE_11,
             CMD_SET_PWM_VALUE_1,
             CMD_SET_PWM_VALUE_2,
             CMD_SET_PWM_VALUE_3,
             CMD_SET_PWM_VALUE_4,
             CMD_SET_PWM_VALUE_15,
             CMD_SET_PWM_VALUE_13,
          ];
}

=item ring_table

The arrangement of the LEDs can be thought of as being arrange logically
as 6 "rings".  This provides access to the rings indexed 0-5.

=cut

has ring_table => (
   is      => 'ro',
   isa     => 'ArrayRef',
   traits  => [qw(Array)],
   handles => {
      get_ring_leds => 'get',
   },
   auto_deref => 1,
   lazy       => 1,
   builder    => '_get_ring_table',
);

sub _get_ring_table
{
   my ( $self ) = @_;

   my $rings = [];

   foreach my $led ( 0 .. 5 )
   {
      $rings->[$led] = [];

      foreach my $arm ( 0 .. 2 )
      {
         my $led_no = $self->get_arm_leds($arm)->[$led];
         push @{$rings->[$led]}, $led_no;
      }
   }

   return $rings;
}

=item set_ring

Sets all of the LEDs in the logical ring indexed 0 - 5 to the value
specified.  Gamma correction is applied to the value.

This isn't immediately applied to the LEDs, C<update> should be called
after all the changes have been applied.

=cut

sub set_ring
{
   my ( $self, $ring, $value ) = @_;

   if ($ring >= 0 && $ring <= 5 )
   {
      if( defined( my $ring_leds = $self->get_ring_leds($ring) ))
      {
         $self->set_leds($ring_leds, $value);
      }
      else
      {
         warn "no ring defined for $ring";
      }
   }
   else
   {
      warn "No ring $ring";
   }
}

=item arm_table

This returns an Array Ref of Array references that reference the LEDs in
each "arm" of the PiGlow.

=cut

has arm_table => (
   is      => 'ro',
   isa     => 'ArrayRef',
   traits  => [qw(Array)],
   handles => {
      get_arm_leds => 'get',
   },
   auto_deref => 1,
   lazy       => 1,
   builder    => '_get_arm_table',
);

sub _get_arm_table
{
   my ( $self ) = @_;

   return [
           [0,1,2,3,4,5],
           [6,7,8,9,10,11],
           [12,13,14,15,16,17]
          ];
}

=item set_arm

Sets the LEDs in the specified "arm" of the PiGlow to the specified value.

Value has gamma correction applied.  

Update isn't applied and the update method should be called when all the
required updates have been performed.
=cut


sub set_arm
{
    my ( $self, $arm, $value ) = @_;

    if ( defined $arm && ($arm >= 0 && $arm <= 2))
    {
         my $arm_leds = $self->get_arm_leds($arm);
         $self->set_leds($arm_leds, $value);
    }
}

=item colour_table

This returns a Hash reference mapping the names of the coloured LEDs
to the groups of LEDs of that colour.

The delegate colours returns the keys, get_colour_leds returns the
list of LEDs

=cut


has colour_table => (
		    is =>  'ro',
                    isa => 'HashRef',
                    traits => [qw(Hash)],
                    handles => {
                      get_colour_leds => 'get',
                      colours	=>	'keys',
                    },
                    auto_deref	=> 1,
                    lazy	=> 1,
 		    builder	=> '_get_colour_table',
                 );

sub _get_colour_table
{
   return {
		white	=> [5,11,17],
                blue	=> [4,10,16],
                green   => [3,9,15],
                yellow  => [2,8,14],
                orange  => [1,7,13],
                red     => [0,6,12]     ,
          };
}

=item set_colour

Sets the LEDs in the specified "colour" of the PiGlow to the specified value.

Value has gamma correction applied.  

Update isn't applied and the update method should be called when all the
required updates have been performed.

=cut


sub set_colour
{
    my ( $self, $colour, $value ) = @_;

    if ( defined $colour)
    {
         if ( defined (my $colour_leds = $self->get_colour_leds($colour) ))
         {
            $self->set_leds($colour_leds, $value);
         }
    }
}

=item gamma_table

This is a map of input PWM values (0 - 255) to gamma corrected values
that produce a more even range of brightness in the LEDs.

The values were lifted from the piglow library for Node.js which in turn
borrowed them from elsewhere.

=cut

has gamma_table => (
                      is => 'ro',
                      isa => 'ArrayRef',
                      traits => [qw(Array)],
                      auto_deref => 1,
                      lazy => 1,
                      builder => '_get_gamma_table', 
                      handles => {
                         map_gamma  => 'get',
                      },
                   );

sub _get_gamma_table
{
   my ($self) = @_;

   return [
      0,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
      1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
      1,   1,   1,   1,   2,   2,   2,   2,   2,   2,   2,   2,   2,   2,
      2,   2,   2,   2,   2,   2,   2,   2,   2,   3,   3,   3,   3,   3,
      3,   3,   3,   3,   3,   3,   3,   3,   4,   4,   4,   4,   4,   4,
      4,   4,   4,   4,   4,   5,   5,   5,   5,   5,   5,   5,   5,   6,
      6,   6,   6,   6,   6,   6,   7,   7,   7,   7,   7,   7,   8,   8,
      8,   8,   8,   8,   9,   9,   9,   9,   10,  10,  10,  10,  10,  11,
      11,  11,  11,  12,  12,  12,  13,  13,  13,  13,  14,  14,  14,  15,
      15,  15,  16,  16,  16,  17,  17,  18,  18,  18,  19,  19,  20,  20,
      20,  21,  21,  22,  22,  23,  23,  24,  24,  25,  26,  26,  27,  27,
      28,  29,  29,  30,  31,  31,  32,  33,  33,  34,  35,  36,  36,  37,
      38,  39,  40,  41,  42,  42,  43,  44,  45,  46,  47,  48,  50,  51,
      52,  53,  54,  55,  57,  58,  59,  60,  62,  63,  64,  66,  67,  69,
      70,  72,  74,  75,  77,  79,  80,  82,  84,  86,  88,  90,  91,  94,
      96,  98,  100, 102, 104, 107, 109, 111, 114, 116, 119, 122, 124, 127,
      130, 133, 136, 139, 142, 145, 148, 151, 155, 158, 161, 165, 169, 172,
      176, 180, 184, 188, 192, 196, 201, 205, 210, 214, 219, 224, 229, 234,
      239, 244, 250, 255
   ];
}

=item gamma_fix_values

This applies the gamma adjustment mapping to the supplied array ref.

=cut

sub gamma_fix_values
{
   my ( $self, $values ) = @_;

   my @values = map { $self->map_gamma($_) } @{$values};

   return \@values;
}

=item reset

Resets the device to its default state.  That is to say all LEDs off.

It will be necessary to re-enable the groups of LEDs again after calling
this.

=cut

sub reset
{
   my ( $self) = @_;
   return $self->_write_byte(CMD_RESET, 0xFF);
}


=item write_block_data

$self->writeBlockData($register_address, $values)

Writes a maximum of 32 bytes in a single block to the i2c device.
The supplied $values should be an array ref containing the bytes to
be written.

The register address supplied should be the first of a consecutive set
of addresses equal to the number of values supplied.  Supplying an 
address that doesn't fit that description is unlikely to work well and
will almost certainly result in undefined behaviour in the device.

=cut

# Device::SMBus seems to have the XS part of this but not the perl.
# I'll use this one if it doesn't

sub write_block_data 
{
    my ( $self, $register_address, $values ) = @_;
    
    my $value  = pack "C*", @{$values};

    my $retval = Device::SMBus::_writeI2CBlockData($self->i2c_file,$register_address, $value);
    return $retval;
}

=back

=head2 CONSTANTS

These define the command registers used by the SN3218 IC used in PiGlow

=over 4

=cut


=item CMD_ENABLE_OUTPUT

If set to 1 the device will be ready for operation, if 0 then it will
be "shutdown"

=cut


=item CMD_ENABLE_LEDS

This should be used for a block write to enable (or disable) all three
groups of LEDs in one go.  The values are a 6 bit mask, one bit for each
LED in the group.

=cut


=item CMD_ENABLE_LEDS_1

A bit mask to enable the LEDs in group 1

=cut


=item CMD_ENABLE_LEDS_2

A bit mask to enable the LEDs in group 2

=cut


=item CMD_ENABLE_LEDS_3

A bit mask to enable the LEDs in group three.

=cut


=item CMD_SET_PWM_VALUES

This should be used in a block write to set the PWM values of all 18 LEDs
at once.  The values should be 8 bit values.

There are also CMD_SET_PWN_VALUE_[1 .. 18] to set the LEDs individually.

=cut



=item CMD_UPDATE

The written LED values are stored in a temporary register and are not
applied to the LEDs until an 8 bit value is written to this register/

=cut


=item CMD_RESET

Writing a value to this register will restore the device to its power
on default (i.e. all LEDs blank)

=back

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This is licensed under the same terms as Perl itself.  Please see the
LICENSE file in the distribution files for the full details.

=head1 SUPPORT

I wrote this because I had the device and I prefer to use Perl.  It
probably does everything I would like it to do.  If you want it to do
something else or find a bug or infelicity, please feel free to fork
the code at github and send me a pull request:

    https://github.com/jonathanstowe/Device-PiGlow

bug reports without patches are likely to be ignored unless you want to
do do something with it that I think is fun and interesting.

=head1 CREDIT WHERE IT'S DUE

This was largely a no brainer.  The author of L<Device::SMBus> did all the
hard work on the Perl side and the implementation details were largely
translated from the PyGlow library. https://github.com/benleb/PyGlow/


=head1  SEE ALSO

L<Device::SMBus>

=cut

1;
