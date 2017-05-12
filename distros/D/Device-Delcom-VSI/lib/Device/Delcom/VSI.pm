package Device::Delcom::VSI;
use warnings;
use strict;
use Device::USB;
use Carp;

use base "Device::USB::Device";

=head1 Device::Delcom::VSI

This class encapsulates access to one or more Delcom VSI devices.

=cut 

=head1 NAME

Device::Delcom::VSI - Use Device::USB to access Delcom VSI devices.

=head1 VERSION

Version 0.08

=cut

our $VERSION = 0.08;

#use constant VENDORID => 0x0fc5;
#use constant PRODUCTID => 0x1223;
use constant VENDORID => 4037;
use constant PRODUCTID => 4643;


my %colors=(
		green	=> 0,
		red	=> 1,
		blue	=> 2,
		yellow	=> 2,
	   );

##my %options; #temporary

my $DEBUG=0;
sub dprint {print @_ if $DEBUG};
sub dprintf {printf @_ if $DEBUG};



=head1 SYNOPSIS

Device::Delcom::VSI provides a Perl object for accessing a Delcom VSI
device using the Device::USB module.

    use Device::Delcom::VSI;

    my $vsi = Device::Delcom::VSI->new();

    $vsi->color_set( red => 'on', blue => 'off' );
    $vsi->led_duty_cycle( 'green', 200, 100 );
    $vsi->color_set( green => 'flash' );

=head1 DESCRIPTION

This module defines a Perl object that represents the data and functionality
associated with a USB device. The object interface provides read-only access
to the important data associated with a device. It also provides methods for
almost all of the functions supplied by libusb. Where necessary, the interfaces
to these methods were changed to better match Perl usage. However, most of the
methods are straight-forward wrappers around their libusb counterparts.

=head2 FUNCTIONS

=over 4

=item new

Create an object for manipulating the first VSI device detected.

Returns a Device::Delcom::VSI object that supports manipulation of the device.

Croaks on error.

=cut

sub new
{
    my $class = shift;
    my $usb = Device::USB->new();
    croak( "couldn't get usb:$!" ) unless $usb;

    my $obj = $usb->find_device( VENDORID, PRODUCTID );
    croak( "couldn't open device: $!" ) unless defined $obj;
    $obj->open();

    return bless $obj , $class;
}


=item list

Generate a list of Device::Delcom::VSI objects, one for each VSI on the
current system.

=cut

sub list
{
    my $class = shift;
    my $usb = Device::USB->new();
    croak( "couldn't get usb:$!" ) unless $usb;
    my @objs = $usb->list_devices( VENDORID, PRODUCTID );
    
    foreach my $obj (@objs)
    {
        $obj->open();
	$obj = bless $obj, $class;
    }
    
    return wantarray ? @objs : \@objs;
}

=item debug_mode

Enable or disable debugging based on the value of the supplied parameter.
A true value enables the debug printing, while a false value disables it.

=cut

sub debug_mode
{
    my $class = shift;
    $DEBUG = shift;
}


#
# Utility function for converting various on/off/1/0 values to proper
# flags. Returns C<undef> if the value is not recognized.
#
#  'on'  -> 1
#   1    -> 1
#  'off' -> 0
#  0     -> 0
#  otherwise -> undef
#
sub _onoff_to_num
{
    my $val = shift;

    if('on' eq $val or '1' eq $val)
    {
	return 1;
    }
    elsif('off' eq $val or '0' eq $val)
    {
	return 0;
    }
    
    return;
}


=item color_set

Turn the leds on, off, or make them flash.

The parameters to this function are expected in pairs: a color followed by
a command. The expected colors are: red, blue, green. For convenience if using
the red/green/yellow version of the VSI, yellow can be used instead of blue 
when issuing commands.

The command can be one of the following:

=over 4

=item on

Turn on the named led.

=item 1

The same as 'on'.

=item off

Turn off the named led.

=item 0

The same as 'off'.

=item flash

Make the named led flash.

=back

=cut

sub color_set
{
    my $self = shift;
    croak( "Odd number of parameters to color_set.\n" ) if scalar( @_ ) % 2;
    my %args = @_;
    my $onbits = 0;
    my $offbits = 0;
    my $flashon = 0;
    my $flashoff = 0;

    foreach my $color (keys %args)
    {
        croak( "Unknown color '$color'\n" ) unless exists $colors{$color};

	my $cmd = $args{$color};
	my $colorbit = 1 << $colors{$color};

	if('flash' eq $cmd)
	{
	    $flashon |= $colorbit;
	}
	else
	{
	    my $num = _onoff_to_num( $cmd );
	    croak( "Unknown color command '$cmd' for '$color'\n" ) unless defined $num;

            $flashoff |= $colorbit;
	    if($num)
	    {
	        $onbits   |= $colorbit;
	    }
	    else
	    {
	        $offbits  |= $colorbit;
	    }
	}
    }
    $self->_port_set_reset( 1, $offbits, $onbits ) if $offbits or $onbits;
    $self->_flash_mode( $flashon, $flashoff ) if $flashon or $flashoff;
}


=item set_prescalar

Set the scaling value for the clock used in generating all frequencies.
Legal values are from 1 to 255. Power on default is 10. Higher numbers
means lower frequency.

=cut

sub set_prescalar
{
    my ($self, $prescalar) = @_;
    croak( "Invalid prescalar value, must be between 1 and 255.\n" )
        if $prescalar < 1 or 255 < $prescalar;

    return $self->_delcom_write_command( 19, 0, $prescalar );
}


=item led_duty_cycle

Set the duty cycle for a given led when it is flashing.

=over 4

=item color

The name of the color to change: red, green, or blue.

=item highdur

The length of time the led is on in each cycle: 1 - 255.

=item lowdur

The length of time the led is off in each cycle: 1 - 255.

=back

=cut

sub led_duty_cycle
{
    my ($self, $color, $highdur, $lowdur) = @_;
    croak( "Invalid color ($color).\n" ) unless exists $colors{$color};

    return $self->_load_duty_cycle( $colors{$color}, $lowdur, $highdur );
}


=item led_sync

Synchronize the LEDs when flashing.

The parameter list consists of a set of pairs of values. Each pair is
a color and a state. Any colors not listed will not be synchronized.

The legal colors are: red, green, or blue

The legal states are: on (1) and off (0).

For example:

  $vsi->led_sync( red => on, green => off, blue => on );

and

  $vsi->led_sync( red => 1, green => 0, blue => 1 );

Have the same meaning, red and blue will come on at the same time
that green is off. Then, they will swap. (Depending on phase delay
and duty cycle, of course.)

=cut

sub led_sync
{
    my $self= shift;
    croak( "Odd number of parameters to led_sync.\n" ) if scalar( @_ ) % 2;
    my %args = @_;

    my $enable = 0;
    my $initial_state = 0;

    foreach my $color (keys %args)
    {
        croak( "Unknown color '$color'\n" ) unless exists $colors{$color};

	my $cmd = $args{$color};
	my $colorbit = 1 << $colors{$color};
        $enable   |= $colorbit;

        my $num = _onoff_to_num( $cmd );
        croak( "Unknown initial state '$cmd' for '$color'\n" )
	    unless defined $num;

	if($num)
	{
	    $initial_state &= ~$colorbit;
	}
	else
	{
	    $initial_state |= $colorbit;
	}
    }
    return $self->_synch_clocks( $enable, $initial_state );
}


=item led_phase_delay

Set the delay of the beginning of the cycle for the specified LED.

=over 4

=item color

The color name of the LEDs to adjust: red, green, or blue.

=item offset

The offset of the beginning of the duty cycle. Legal values are
0 - 255. The units are 1.024ms times the prescalar value.

=back

=cut

sub led_phase_delay
{
    my ($self, $color, $offset) = @_;
    croak( "Unknown color '$color'\n" ) unless exists $colors{$color};

    return $self->_load_phase_delay( $colors{$color}, $offset );
}


=item led_intensity

Set the brightness of a particular color of LED.

The parameter list consists of a set of pairs of values. Each pair is
a color and an intensity. Any colors not listed will not be changed.

=over 4

=item color

The color name of the LEDs to adjust: red, green, or blue.

=item intensity

Brightness as a percentage. Default value is 80. Setting all LEDs
above 80 could potentially exceed the current limit of the USB port.

=back

=cut

sub led_intensity
{
    #my ($self, $color, $intensity) = @_;
    my $self= shift;
    croak( "Odd number of parameters to led_intensity.\n" ) if scalar( @_ ) % 2;
    my %args = @_;

    foreach my $color (keys %args)
    {
        croak( "Unknown color '$color'\n" ) unless exists $colors{$color};
	my $intensity = $args{$color};
    	$self->_light_intensity( $colors{$color}, $intensity );
    }
}


=item set_event_count

Enable or disable the button event counter.

A value of 'on' or 1 enables the counter.
A value of 'off' or 0 disables it.

=cut

sub set_event_counter
{
    my ($self, $on_off) = @_;

    my @enable;
    my $num = _onoff_to_num( $on_off );
    croak( "Unrecognized event_counter state '$on_off'\n" ) unless defined $num;

    if($num)
    {
        @enable = ( 0, 1 );
    }
    else
    {
        @enable = ( 1, 0 );
    }

    return $self->_enable_event_counter( @enable );
}


=item buzzer_off

Turn off the buzzer.

=cut

sub buzzer_off
{
    my $self = shift;
    
    return $self->_buzzer_setup( 0, 0 );
}


=item buzzer_on

Turn on the buzzer, setting its frequency and duty cycle.

The parameter list consists of a set of pairs of values. Each pair is
optional, and a default value will be substituted if a parameter is missing.

=over 4

=item freq

Frequency value in 256us increments. Legal values are from 1 to 255. Default is 10.

=item repeat

Number of cycles to repeat. Legal values are 1 - 254. Default is 3. There are also
two special values: 0 (full) and 255 (forever)

A repeat value of 0 or 'full' causes the buzzer to run continuously at
a 100% duty cycle (ignoring the duty_on and duty_off values).

A repeat value of 255 or 'forever' causes the buzzer to run with the
given frequency and duty cycle continuously.

=item duty_on

The on time portion of the duty cycle. Default is 3.

=item duty_off

The off time portion of the duty cycle. Default is 3.

=back

=cut

sub buzzer_on
{
	my $self = shift;
	my %args = @_;
	croak( "Odd number of parameters to buzzer_on.\n" ) if scalar( @_ ) % 2;
#    my ($self, $freq, $repeat, $duty_on, $duty_off) = @_;
	my $freq = $args{freq} || 10;
	my $repeat = $args{repeat} || 3;
	my $duty_on = $args{duty_on} || 3;
	my $duty_off = $args{duty_off} || 3;
    
    $repeat = 0   if !defined $repeat or 'full' eq $repeat;
    $repeat = 255 if defined $repeat and 'forever' eq $repeat;
    $repeat &= 0xff;

    return $self->_buzzer_setup( 1, $freq, $repeat, $duty_on, $duty_off );
}


=item button_setup

Configure the button modes of operation.

The parameters to this method are pairs of values. The first item of
each pair is a mode string and the second specifies whether the mode
is 'on' (1) or 'off' (0). The defined modes are:

=over 4

=item clear

Turn off the buzzer and all LEDs when the button is pressed.

=item beep

Generate an audible signal when the button is pressed.

=back

Either or both modes can be turned on or off without effecting the other.

Although this method configures the modes. The button mode is not active
until the button event counter is enabled. For example, to turn on both
modes, use the following code:

  $vsi->button_setup( clear => 'on', beep => 'on' );
  $vsi->set_event_counter( 'on' );

Once the event counter is enabled, this method can be used to change the
button mode without re-enabling the counter.

=cut

sub button_setup
{
    my $self = shift;
    croak( "Odd number of parameters to button_setup.\n" ) if scalar( @_ ) % 2;
    my %args = @_;
    
    my $enable = 0;
    my $disable = 0;

    foreach my $key (keys %args)
    {
        my $num = _onoff_to_num( $args{$key} );
        croak( "Invalid state for mode '$key': '$args{key}'\n" ) unless defined $num;
	
        if('clear' eq $key)
	{
	    ($num ? $enable : $disable) |= 64;
	}
	elsif('beep' eq $key)
	{
	    ($num ? $enable : $disable) |= 128;
	}
	else
	{
	    croak( "Unrecognized button mode '$key'\n" );
	}
    }
    
    return $self->_button_setup( $enable, $disable );
}


=item read_ports

Read ports 0 and 1 on the VSI and return the bytes as a two item list.

=cut

sub read_ports
{
    my $self = shift;
    
    my $buffer = $self->_delcom_read_command( 0 );

    return unless defined $buffer;

    return unpack( "CC", $buffer );
}


=item read_button

Read the current value of the button on the VSI. A value of 0 means
the button is being pushed. A value of 1 means the button is not
being pushed.

=cut

sub read_button
{
    my $self = shift;

    return ($self->read_ports())[0] & 1;
}


=item read_buzzer

Read the current value of the buzzer pin. Possible values are 0 and 1.

=cut

sub read_buzzer
{
    my $self = shift;

    return (($self->read_ports())[1] & 8)>>3;
}


=item read_leds

Read the current values of the LED pins. The result is returned as a
reference to a hash, containing the pin values. The keys to the hash are
the color names red, green, and blue. A value of 0 means the LEDs on that
color are on. A value of 1 means the LEDs of that color are off.

=cut

sub read_leds
{
    my $self = shift;
    my $leds = ($self->read_ports())[1];
    return {
        green => ($leds & 1),
        red => ($leds & 2)>>1,
        blue => ($leds & 4)>>2,
    };
}


=item read_event_counter

Read the current value of the button event counter. This method returns
the current value of the counter and resets the counter to 0.

The event counter is a 4 byte value. If the event counter exceeds the
value that can be stored in 4 bytes, a special value of 'overflow' is
returned.

=cut

sub read_event_counter
{
    my $self = shift;
    my ($count, $overflow) = $self->_read_event_counter();

    return $overflow ? 'overflow' : $count;
}


=item read_system_variables

Read the system variables. The results are decoded and returned as
a hash reference. The data stored in the hash reference is:

=over 4

=item buzzer_running

True if the buzzer is currently running.

=item counter_overflow

True if the button event counter has overflowed.

=item auto_clear

True if the button is configured to clear when pressed.

=item auto_confirm

True if the button is configured to beep when pressed.

=item prescalar

The value of the closk generator pre-scalar.

=item address

The USB port address.

=back

=cut

sub read_system_variables
{
    my $self = shift;
    
    my @sysvars = $self->_read_system_variables();
    
    return unless @sysvars;

    return {
        buzzer_running =>   ($sysvars[0] & 0b0001_0000) >> 4,
        counter_overflow => ($sysvars[0] & 0b0010_0000) >> 5,
        auto_clear =>       ($sysvars[0] & 0b0100_0000) >> 6,
        auto_confirm =>     ($sysvars[0] & 0b1000_0000) >> 7,
	prescalar => $sysvars[1],
	address => $sysvars[2],
    };
}


=item read_system_variables

Read the formware information. The results are decoded and returned as
a hash reference. The data stored in the hash reference is:

=over 4

=item serial_number

The 4-byte serial number.

=item version

The current firmware version.

=item year

The 2 digit year of the firmware date.

=item month

The month number of the firmware date.

=item day

The day number of the month of the firmware date.

=back

=cut

sub read_firmware
{
    my $self = shift;
    
    my @firmware = $self->_read_firmware();

    return unless @firmware;

    return {
        serial_number =>   $firmware[0],
        version => $firmware[1],
        day =>  $firmware[2],
        month => $firmware[3],
	year => $firmware[4],
    };
}



=begin COMMENT 

sub color_set {
	#my $self = shift;
	#my $dev = $$self;
	my $dev = ${(shift)};
	my %args = @_;
	foreach my $key (keys %args) {
		my $color_name = $key;
		my $color = $colors{$color_name};
		print STDERR "bad color: $color_name in color_set\n" unless defined $color;
		next unless defined $color;
		my $cmd = $args{$key}; # should be on, off, flash
		#dprint "in color_set, color is $color_name\n";
	
		if ($cmd eq "on"){
			#dprint "turning on $color_name\n";
			_color_on($dev,$color);
			_color_flash($dev,$color_name,0);
		} elsif ($cmd eq "off") {
			#dprint "turning off $color_name\n";
			_color_off($dev,$color);
			_color_flash($dev,$color_name,0);
		} elsif ($cmd eq "flash") {
			#dprint "turning flashing on $color_name\ncolor is $color\n";
			_color_flash($dev,$color_name,1);
		}
	}
}

sub _color_on {
	my $dev = shift;
	my $color = shift;

	$dev->control_msg(
	0xc8,
	0x12,
	(12 * 0x100) + 10,
	(1 << $color), #MSB on
	"",
	0x08,
	5000
	);
}

sub _color_off {
	my $dev = shift;
	my $color = shift;

	$dev->control_msg(
	0xc8,
	0x12,
	(12 * 0x100) + 10,
	((1 << $color) * 0x100), #LSB off
	"",
	0x08,
	5000
	);
}

sub _color_flash {
	my $dev = shift;
	my $color_name = shift;
		my $color = 1 << $colors{$color_name};
	#dprint "in _color_flash, color is $color\n";
	my $onoff = shift;
	my $lsb;
	my $msb;

	if ($onoff) {
		#dprint "setting flash off for $color\n";
		$lsb=0;
		$msb=$color;
	}else{
		#dprint "setting flash on for $color\n";
		$lsb=$color;
		$msb=0;
	}
	$dev->control_msg(
			0x48,
			0x12,
			(10 + (20 * 256)), # 20, enable/disable flash mode
			($lsb   + ($msb * 256)), # lsb disables, msb enables
			0x0,
			0x8,
			5000);
}

sub sync {
	my $dev = ${(shift)};
	my %args = @_;
	
	if (@_){ #set our delays if we have args
		foreach my $key (keys %args) {
			my $color_name = $key;
			my $color = $colors{$color_name};
			unless (defined $color) {
				print STDERR "bad color: $color_name in sync\n" unless defined $color;
				next;
			}
			my $delay = $args{$key};
			my $minor = $color + 26;
			dprint "setting value of $delay for $color_name\tusing minor of $minor\n";
			
			$dev->control_msg(
					0x48,
					0x12,
					(10 + $minor * 0x100),
					#0 + $delay * 0x100,
					$delay + 0 * 0x100,
					0,
					8,
					5000);
		}

	}
	$dev->control_msg( #no args? just sync
			0x48,
			0x12,
			(10 + 25 * 0x100),
			7 + 7 * 0x100,
			0,
			8,
			5000);
}





sync()                          if (defined $options{sync});
scaler($options{scaler})        if (defined $options{scaler});
buzzer($options{buzzer})        if (defined $options{buzzer});
clearconfirm($options{clear})   if (defined $options{clear});
clearconfirm($options{confirm}) if (defined $options{confirm});
vsiread($options{read})            if (defined $options{read});
cancel()                        if (defined $options{cancel});

sub cleanup_options{
	my $opts = shift;
	foreach my $key (keys %$opts){
		$$opts{$key} =~ s/,/ /g;
	}
}

sub led {
	my $color = shift;
	my $options = shift;
	dprint "LED: $color: $options\n";
}

sub led_onoff {
	my $color = shift;
	my $onoff = shift;
	if ($onoff eq "on") {
		dprint "turning $color on\n";
	}else{
		dprint "turning $color off\n";
	}
}

sub led_flash {
	my $color = shift;
	dprint "flashing $color\n";
}

sub led_duty {
	my $color = shift;
	my ($dutyon, $dutyoff) = @_;
	dprint "$color: dutyon: $dutyon\tdutyoff: $dutyoff\n";
}

sub led_intensity {
	my $color = shift;
	my $intensity = shift;
	dprint "$color: intensity: $intensity\n";
}

sub led_syncoffset {
	my $color = shift;
	my $syncoffset = shift;
	dprint "$color: syncoffset: $syncoffset\n";
}

sub cancel {
	dprint "cancelling all\n";
}

sub scaler {
	my $scaler = shift;
	dprint "scaler: $scaler\n";
}

sub buzzer {
	my $options = shift;
	dprint "buzzer options: $options\n";
}

sub buzzer_default {
	my $repeat    = 3;
	my $frequency = 5;
	my $dutyon    = 6;
	my $dutyoff   = 5;
	buzzer ($repeat, $frequency, $dutyon, $dutyoff);
}
sub buzzer_manual {
	my ($repeat, $frequency, $dutyon, $dutyoff) = @_;
	dprint "buzzer repeat: $repeat\n";
	dprint "buzzer frequency: $frequency\n";
	dprint "buzzer dutyon: $dutyon\n";
	dprint "buzzer dutyoff: $dutyoff\n";
}

sub clearconfirm {
	my $cc = shift;
	my $onoff = shift;
	my $ccbits;
	$ccbits = 128 if $cc eq "confirm";
	$ccbits = 64  if $cc eq "clear";
	if ($onoff eq "on") {
		dprint "$cc: on\n";
	}else{
		dprint "$cc: off\n";
	}
}

sub vsiread {
	my $options = shift;
	dprint "read options: $options\n";
}

=cut

#
# Utility method for writing to the ports
#
#  port - port number: 0 or 1
#  byte - the value to write to that port.
#
sub _write_port
{
    my ($self, $port, $byte) = @_;
    croak( "Invalid port, only 0 and 1 are allowed.\n" ) if $port < 0 or 1 < $port;

    dprintf( "_write_port( port:$port, byte:%02x )\n", $byte );
    return $self->_delcom_write_command( 1 + $port, 0, ($byte & 0xff) );
}

#
# Utility method for writing to both ports
#
#  port0val - value to write to port 0
#  port1val - value to write to port 1
#
sub _write_both_ports
{
    my ($self, $port0val, $port1val) = @_;
    
    dprintf( "_write_both_ports( port0val:%02x, port1val%02x )\n", $port0val, $port1val );
    return $self->_delcom_write_command( 10, ($port1val & 0xff), ($port0val & 0xff) );
}


#
# Utility method for (re)setting individual bits on a port.
#
#  port - port number: 0 or 1
#  setbits - bitmask showing which bits to turn on
#  resetbits - bitmask showing which bits to turn off
#
# In case of conflict, reset overrides set.
#
sub _port_set_reset
{
    my ($self, $port, $setbits, $resetbits) = @_;
    croak( "Invalid port, only 0 and 1 are allowed.\n" ) if $port < 0 or 1 < $port;
    
    dprintf( "_port_set_reset( port:$port, setbits:%08b, resetbits:%08b )\n", $setbits, $resetbits );
    return $self->_delcom_write_command( 11+$port, ($setbits & 0xff), ($resetbits & 0xff) );
}


#
# Utility method for setting the flash modes for the leds
#
#  enable - bitmask showing which LEDs to flash
#  disable - bitmask showing which LEDs to disable flashing
#
# In case of conflict, disable overrides enable.
#
sub _flash_mode
{
    my ($self, $enable, $disable) = @_;
    $enable  &= 0xf;
    $disable &= 0xf;

    dprintf( "_flash_mode( enable:%08b, disable:%08b )\n", $enable, $disable );
    return $self->_delcom_write_command( 20, $enable, $disable );
}


#
# Utility method for loading the duty cycle on a flashing LED.
#
#  colornum - the color number to set: 0, 1, or 2
#  highdur - period when the pin is high
#  lowdur - period when the pin is low
#
# Resolution of the period is 1.024 ms * pre-scalar value
# Resolution of the duty cycle is 0.39 percent.
#
sub _load_duty_cycle
{
    my ($self, $colornum, $highdur, $lowdur) = @_;
    croak( "Invalid color number ($colornum), must be 0, 1, or 2.\n" )
        if $colornum < 0 or 2 < $colornum;

    dprint( "_load_duty_cycle( colornum:$colornum, highdur:$highdur, lowdur:$lowdur )\n" );
    return $self->_delcom_write_command( 21+$colornum, $lowdur, $highdur );
}


#
# Synchronize the clocks for the different led colors.
#
#  enable - bitmask telling which colors to change.
#  initial_state - for the on bits in the bitmask, set the initial state
#     of the flash.
#
# This command also zeros the phase delay.
#
sub _synch_clocks
{
    my ($self, $enable, $initial_state) = @_;

    dprintf( "_synch_clocks( enable:%08b, intial:%08b )\n", $enable, $initial_state );
    return $self->_delcom_write_command( 25, $initial_state, $enable );
}


#
# Set the phase delay for a particular color
#
#  colornum - the color number for the LEDs to change: 0, 1, or 2
#  offset - the delay until the beginning of the flash cycle. Legal
#    values are 0-255. Resolution is 1.024ms * pre-scalar value
#
sub _load_phase_delay
{
    my ($self, $colornum, $offset) = @_;
    croak( "Invalid color number ($colornum), must be 0, 1, or 2.\n" )
        if $colornum < 0 or 2 < $colornum;

    dprint( "_load_phase_delay( colornum:$colornum, offset:$offset )\n" );
    return $self->_delcom_write_command( 26+$colornum, 0, $offset );
}


#
# Set the intensity of a particular color of LEDs
#
#  colornum - the color number for the LEDs to change: 0, 1, or 2
#  intensity - intensity: 0-100. Defaults to 80 at power up.
#
# Setting all LEDs higher than 80 may exceed the current limit of the
# USB port if all LEDs are on at once.
#
sub _light_intensity
{
    my ($self, $colornum, $intensity) = @_;
    croak( "Invalid color number ($colornum), must be 0, 1, or 2.\n" )
        if $colornum < 0 or 2 < $colornum;
    croak( "Invalid intensity ($colornum), must be between 0 and 100.\n" )
        if $intensity < 0 or 100 < $intensity;

    dprint( "_light_intensity( colornum:$colornum, intensity:$intensity )\n" );
    return $self->_delcom_write_command( 34, $intensity, $colornum );
}


#
# Enable or disable the event counter
#
#  disable - bitmask disabling pins to count events
#  enable - bitmask enabling pins to count events
#
# The button is the low-order bit.
#
sub _enable_event_counter
{
    my ($self, $disable, $enable) = @_;
    $enable  &= 0xff;
    $disable &= 0xff;

    dprintf( "_enable_event_counter( enable:%08b, disable:%08b )\n", $enable, $disable );
    return $self->_delcom_write_command( 38, $disable, $enable );
}


sub _buzzer_setup
{
    my ($self, $on_off, $freq, $repeat, $duty_on, $duty_off) = @_;
    $on_off ||= 0;
    $freq ||= 0;
    $repeat ||= 0;
    $duty_on ||= 0;
    $duty_off ||= 0;
    my $pointer = pack("CCC", $repeat, $duty_on, $duty_off);

    dprintf( "_buzzer_setup( on_off:$on_off, freq:%02x, repeat:$repeat, dutyon:$duty_on, duty_off:$duty_off )\n", $freq );
    return $self->control_msg(
	0x48, # 0xc8 for reading, 0x48 for writing
	0x12,
	(10 | (70 << 8)),
	($on_off | ($freq << 8)),
	$pointer,
	0x8,
	5000 );
}



sub _button_setup
{
    my ($self, $enable, $disable) = @_;
    $enable  &= 0xff;
    $disable &= 0xff;

    dprintf( "_button_setup( enable:%08b, disable:%08b )\n", $enable, $disable );
    return $self->_delcom_write_command( 72, $enable, $disable );
}


sub _read_event_counter
{
    my $self = shift;
    
    my $buffer = $self->_delcom_read_command( 8 );

    return unless defined $buffer;
    
    return unpack( "VC", $buffer );
}


sub _read_system_variables
{
    my $self = shift;
    
    my $buffer = $self->_delcom_read_command( 9 );

    return unless defined $buffer;
    
    return (unpack( "CCCCC", $buffer ))[0,1,4];
}


sub _read_firmware
{
    my $self = shift;
    
    my $buffer = $self->_delcom_read_command( 10 );

    return unless defined $buffer;
    
    return unpack( "VCCCC", $buffer );
}

sub _delcom_write_command
{
    my ($self, $cmd, $msb, $lsb) = @_;
    $cmd &= 0xff;
    $msb &= 0xff;
    $lsb &= 0xff;

    if(0 > $self->control_msg(
	0x48,
	0x12,
	(10 | ($cmd << 8)),
	($lsb | ($msb << 8)),
	undef,
	0x8,
	5000))
    {
        croak( "USB access failed: $!\n" );
    }
}


sub _delcom_read_command
{
    my ($self, $cmd) = @_;
    my $buffer = "\0"x8;
    my $retval = 0;

    if(0 > $self->control_msg(
	0xc8,
	0x12,
	(11 | ($cmd << 8)),
	0x00,
	$buffer,
	0x8,
	5000))
    {
        croak( "USB access failed: $!\n" );
    }

    return $buffer;
}
=back

=head1 DIAGNOSTICS

This is an explanation of the diagnostic and error messages this module
can generate.

=over 4

=item couldn't get usb:{perror}

Could not access the libusb library or the USB busses. The {perror} should
be an OS-specific message that will shed further light on the problem.

=item couldn't open device: {perror}

The Delcom VSI USB device was found, but it could not be opened. The {perror}
should be an OS-specific message that will shed further light on the problem.

=item Odd number of parameters to color_set.

The parameters to the color_set method must be pairs consisting of a color and
a command.

=item Unknown color '$color'

The supplied color name was not correct. This may be caused by a misspelling,
an incorrect color, or by parameters getting out of sequence.

=item Unknown color command '$cmd' for '$color'

The commands string supplied for the named color is unrecognized. This may be
caused by a misspelling, actual bad command, or by parameters getting out of
sequence.

=item Invalid prescalar value, must be between 1 and 255.

The number passed to set_prescalar was outside the legal range.


=back


=head1 DEPENDENCIES

This module depends on the Carp and use Device::USB modules, as well as
the strict and warnings pragmas.

=head1 AUTHOR

Paul Archer (paul at paularcher dot org)
G. Wade Johnson (wade at anomaly dot org)

Houston Perl Mongers Group

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-delcom-vsi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::Delcom::VSI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks go to various members of the Houston Perl Mongers group for input
on the module. But thanks mostly go to Paul Archer who proposed the project
and helped with the development.

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2014 Houston Perl Mongers

Device::Delcom::VSI is released under the GNU Public License (GPL).

=cut

1;
__END__

=head1 NAME

Device::Delcom::VSI - Interface to the Delcom Engineering "Visual Signal Indicator" USB device


=head1 SYNOPSIS

 vsi --man | --help
 vsi [--red=command(,command,...)] [--green=command(,command,...)] [--blue=command(,command,...)]
          [--all=command(,command,...)]
          [--sync] [--scaler] [--cancel]
          [--buzzer=command(,command,...)]
          [--button=command(,command,...)]
          [--read=command(,command,...)]
 echo "command,command" |vsi


=head1 BACKGROUND

Delcom Engineering (http://www.delcom-eng.com) makes a "Visual Signal Indicator",
which is a USB based device with three colors of LEDs (8 each of red, green, and
blue--or optionally red, green, and yellow) plus a buzzer. Additionally, the top
of the device acts as a button which activates an internal switch. The button can
be set to turn off the LEDs and the buzzer, and/or to give a confirmation chirp.
The button press can be read (by this script, even) to potentially control
external events. The "VI" is about 2" in diameter, and about 2.2" tall. It is
threaded on the bottom to take a 1/4" pipe for pole mounting.  Additionally, a
one-color (red or yellow) device is available. This program will probably support
it, but until someone wants to donate one to us, we won't be able to test that
theory.

=head1 DESCRIPTION

B<Device::Delcom::VSI> provides a complete Perl interface to the Delcom "VI" device,
including setting all parameters and reading all available data. B<Device::Delcom::VSI>
relies on Device::USB and the underlying libusb library.


=head1 OPTIONS

=over 4

=item B<--help>

	Print a brief help message and exits.

=item B<--man>

	Prints the manual page and exits.

=item B<LED functions>

=item B<--red>

=item B<--green>

=item B<--blue>

=item B<--all> - works on all three colors at once

=over 8

=item B<on> - turns LED on (steady)

=item B<off> - turns LED off

=item B<flash> - turns LED on (flashing).

=item B<duty> I<on> I<off> - sets the length of the flash duty cycle (I<on>, I<off> = 1-255)


=item B<intensity> I<val> - sets the brightness (I<val> = 1-100) NB: Delcom reccommends that if all
three colors are on, the brightness not be set to over 80 (which is the default) to avoid
exceeding the USB spec for power draw.

=item B<syncoffset> I<val> - sets an initial delay when syncing (see 'sync')

=back

=head1

=over 4

=item B<Misc commands>

=item B<--cancel> - turns off all LEDs and buzzer

=item B<--sync> - synchronizes the flashing of the different LEDs after any syncoffset value is applied
to the appropriate LED, then clears the syncoffset. (In the future, this command may allow for specific
LEDs to be sync'ed (ie. red and green only).

=item B<--scaler> I<val> - multiplier for the flash duty cycle. Default is 10 (I<val> = 1-255).

=item B<--buzzer> 

=over 8

=item B<repeat> I<val> - number of times to repeat (I<val> = 0-255). 0 and 255 have special meaning.
A value of 0 places the buzzer in a continuous on state, and a value of 255 will cause the buzzer
to repeat until it is manually turned off.

=item B<frequency> I<val> - relative frequency (I<val> = 0-254). 

=item B<dutyon> I<val> - duty the buzzer is on (I<val> = 1-255).

=item B<dutyoff> I<val> - duty the buzzer is off (I<val> = 1-255).

=item B<on> turns on buzzer with default values

=item B<off> - turns off (just the) buzzer

Each unit for dutyon and dutyoff is approximately .05 seconds.

=back


=item B<--clear> - sets whether pressing the button will turn off the LEDs and buzzer when pressed.

=item B<--confirm> - sets whether the buzzer will emit a confirmation double-chirp when the button is pressed.

=over 8

=item B<on> turns feature on

=item B<off> turns feature off

=back

=item B<Read commands>

=item B<--read>

=over 8

=item B<firmware> - returns firmware version, firmware date in DD/MM/YYYY format, and device serial number.

=item B<buttoncounter> - returns number of times button has been pressed since last read. Resets counter automatically.

=item B<buttonstate> - returns current state of button, and whether the auto clear and auto confirm modes are on.

=item B<ledstate> - returns state of the three leds.

=item B<buzzerstate> - returns current state of buzzer.

=item B<scaler> - returns the current value of the clock scaler.

=item B<clear> - returns whether auto clear is set.

=item B<confirm> - returns whether auto confirm is set.

=head1
AUTHORS

=over 4

 Paul Archer (paul at paularcher dot org)
 G. Wade Johnson (gwadej at anomaly dot org)

=head1
DEPENDENCIES

=over 4

Device::USB
	
=head1
BUGS

=over 4

Probably.

=head1
LICENSE

=over 4

vsi is released under the GNU Public License (GPL).

=cut
	control_msg($handle,
			0xc8,# 0x48-write, 0xc8-read
			0x12,# 18 (0x12 hex) Delcom
			(10 + ($minor * 256)),# 10-write cmd, 11-read cmd; minor is high-order byte
			(LSB   + (MSB * 256)), # lsb off, msb on
			0x0, # array pointer with write data
			0x8, # number of bytes written
			5000); # timeout value for if cmd fails
