package Device::Chip::PCA9685;

use strict;
use warnings;

our $VERSION = 'v0.9';

use base qw/Device::Chip/;

use Future;
use Time::HiRes q/usleep/;

=head1 NAME

C<Device::Chip::PCA9685> - A C<Device::Chip> implementation for the PCA9685 chip

=head1 DESCRIPTION

This class implements a L<Device::Chip> interface for the PCA9685 chip, a 12-bit 16 channel PWM driver.

=head1 SYNOPSIS

    use Device::Chip::PCA9685;
    use Device::Chip::Adapter;

    my $adapter = Device::Chip::Adapter->new_from_description("LinuxKernel");

    my $chip = Device::Chip::PCA9685->new();
    # This is the i2c bus on an RPI 2 B+
    $chip->mount($adapter, bus => '/dev/i2c-1')->get;
    
    $chip->enable()->get;
    $chip->set_frequency(400)->get; # 400 Hz
    
    $chip->set_channel_value(10, 1024)->get; # Set channel 10 to 25% (1024/4096)
    
    $chip->set_channel_full_value(10, 1024, 3192)->get; # Set channel 10 to ON at COUNTER=1024, and OFF at COUNTER=3192 (50% duty cycle, with 25% phase difference)

=head1 METHODS

=cut

my %REGS = (
    MODE1 => {addr => 0},
    MODE2 => {addr => 1},
    SUBADR1 => {addr => 2},
    SUBADR2 => {addr => 3},
    SUBADR3 => {addr => 4},
    ALLCALLADR => {addr => 5},
    ALL_CHAN_ON => {addr => 0xFA}, # 16bit
    ALL_CHAN_OFF => {addr => 0xFC}, # 16bit
    PRE_SCALE => {addr => 0xFE},
    TEST_MODE => {addr => 0xFF},
);

for my $n (0..15) {
    $REGS{"CHAN${n}_ON"}  = {addr => 0x06 + $n * 4}; # 16bit
    $REGS{"CHAN${n}_OFF"} = {addr => 0x08 + $n * 4}; # 16bit
}

use utf8;

use constant PROTOCOL => "I2C";

sub _read_u8 {
    my $self = shift;
    my ($register) = @_;
    
    my $regv = $REGS{$register}{addr};
    
    $self->protocol->write_then_read("\0", 1)->then( sub {
        my ($value) = @_;
        return Future->done(unpack("C", $value));
    });
}

sub _write_u8 {
    my $self = shift;
    my ($register, $value) = @_;

    my $regv = $REGS{$register}{addr};

    $self->protocol->write(pack("C C", $regv, $value));
}

sub _write_u16 {
    my $self = shift;
    my ($register, @values) = @_;

    my $regv = $REGS{$register}{addr};

    $self->protocol->write(pack("C (S<)*", $regv, @values));
}

sub I2C_options {my $self = shift; return (addr => 0x40, @_)}; # pass it through, but allow the address to change if passed in, should use a constructor instead

=head2 set_channel_value

    $chip->set_channel_value($channel, $time_on, $offset = 0)->get
    
Sets a channel PWM time based on a single value from 0-4095.  Starts the channel to turn on at COUNTER = 0, and off at $time_on.
C<$offset> lets you stagger the time that the channel comes on and off.  This lets you vary the times that channels go on and off 
to reduce noise effects and power supply issues from large loads all coming on at once.

C<$on_time> := 0; C<$off_time> := $time_on;

=cut

sub set_channel_value {
    my $self = shift;
    my ($chan, $time_on, $offset) = @_;
    $offset //= 0;
    
    # set the high parts first, we shouldn't ever have backtracking then

    if ($time_on < 0 || $time_on >= 4096) {
        $time_on = $time_on >= 4096 ? 4095 : 0;
        warn "Channel outside allowed value, clamping: $chan, $time_on\n";
    }

    $offset %= 4096; # wrap the offset around, that way you can increment it by any amount and have it work as expected
    $time_on = ($time_on + $offset) % 4096; # wrap it around based on the offset.
    
    $self->set_channel_full_value($chan, $offset, $time_on);
}

=head2 set_channel_full_value

    $chip->set_channel_full_value($channel, $on_time, $off_time)->get
    
Set a channel value, on and off time.  Lets you control the full on and off time based on the 12 bit counter on the device.

=cut

sub set_channel_full_value {
    my ($self, $chan, $on_t, $off_t) = @_;

    $self->_write_u16("CHAN${chan}_ON" => ($on_t  & 0x0FFF), ($off_t & 0x0FFF));
}

=head2 set_channel_on

    $chip->set_channel_on($channel)->get
    
Set a channel to full on.  No off time at all.

=cut

sub set_channel_on {
    my ($self, $chan) = @_;
    
    # Set bit 4 of ON high, this is the bit that sets the channel to full on
    $self->_write_u16("CHAN${chan}_ON" => 0x1000, 0x0000);
}

=head2 set_channel_off

    $chip->set_channel_off($channel)->get
    
Set a channel to full off.  No on time at all.

=cut

sub set_channel_off {
    my ($self, $chan) = @_;
    
    # Set bit 4 of OFF high, this is the bit that sets the channel to full off
    $self->_write_u16("CHAN${chan}_ON"  => 0x0000, 0x1000);
}

=head2 set_default_mode

    $chip->set_default_mode()->get
    
Reset the default mode back to the PCA9685.

=cut

sub set_default_mode {
    my $self = shift;
    # Sets all the mode registers to the chip defaults
    Future->needs_all(
        $self->_write_u8(MODE1 => 0b0000_0001),
        $self->_write_u8(MODE2 => 0b000_00100),
    );
}

=head2 set_frequency

    $chip->set_frequency()
    
Set the prescaler to the desired frequency for PWM.  Returns the real frequency due to rounding.

=cut

sub set_frequency {
    my $self = shift;
    my ($freq) = @_;
    use Data::Dumper;

    my $divisor = int( ( 25000000 / ( 4096 * $freq ) ) + 0.5 ) - 1;
    if ($divisor < 3) { die "PCA9685 forces the scaler to be at least >= 3 (1526 Hz)." };
    if ($divisor > 255) { die "PCA9685 forces the scaler to be <= 255 (24Hz)." };

    my $realfreq = 25000000 / (($divisor + 1)*(4096));
    
    my $old_mode1;
    $self->_read_u8("MODE1")->then( sub {
        ( $old_mode1 ) = @_;

        my $new_mode1 = ($old_mode1 & 0x7f) | 0x10; # Set the chip to sleep, make sure reset is disabled while we do this to avoid noise/phase differences
    
        $self->_write_u8(MODE1 => $new_mode1);
    })->then( sub {
        Future->needs_all(
            $self->_write_u8(PRE_SCALE => $divisor),
            $self->_write_u8(MODE1 => $old_mode1),
        );
    })->then( sub {
        usleep(5000);
        $self->_write_u8(MODE1 => $old_mode1 | 0x80); # turn on the external clock, should this be optional?
    })->then( sub {
        return Future->done( $realfreq );
    });
}

=head2 enable

    $chip->enable()->get

Enable the device.  Must be the first thing done with the device.

=cut

sub enable {
    my $self = shift;

    # 0x20 == AI, auto-increment addresses during register transfer
    #   Useful for 16bit read/write
    $self->_write_u8(MODE1 => 0x20);
}

=head1 AUTHOR

Ryan Voots, <simcop2387@simcop2387.info>
Paul 'LeoNerd' Evans <leonerd@leonerd.org.uk>

=cut

1;
