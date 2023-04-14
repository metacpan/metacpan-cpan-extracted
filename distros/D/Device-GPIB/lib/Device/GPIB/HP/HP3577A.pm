# HP3577A.pm
# Perl module to control a HP 3477A Network Analyser from perl
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::HP::HP3577A;
@ISA = qw(Device::GPIB::Generic);
use Device::GPIB::Generic;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /^HP3577/)
    {
	warn "Not a HP3577 at $self->{Address}: $self->{Id}";
	return;
    }
    return $self
}

# Get current instrument state with LMO and return it
# LMO = Learn Mode Out
sub lmo($)
{
    my ($self) = @_;
    
    my $state = $self->sendAndRead('LMO');
    die "LMO output file is not 1100 bytes long so its probably not an instrument state file\n"
	unless length($state) == 1100;
    
    return $state;
}

# Write $state to instrument state with LMI
# LMI = Learn Mode In
sub lmi($$)
{
    my ($self, $state) = @_;

    die "LMI input is not 1100 bytes long so its probably not an instrument state file\n"
	unless length($state) == 1100;
    
    die "LMI input does not start with I# so its probably not an instrument state file\n"
	unless $state =~ /^#I/;

    $self->send("LMI;" . $state);
}

############################################################
# Graphics commands for drawing to the HP3577 screen
############################################################

# Commands are assembled in this buffer and then sent as a whole, followed by <EOI>

my $graphics_buffer = '';
    
# Clear the screen prior to graphics use
sub graphics_clear($)
{
    my ($self) = @_;

    # Annotation clear
    # Enable commands in display memory
    # Graticule off
    # Characters off
    $self->send("ANC;AN1;TR1;DF0;GR0;CH0");
}

# Start/restart a sequence of graphics commands
sub graphics_start($)
{
    my ($self) = @_;
    
    $graphics_buffer = "ENG#I";

    # Start at address 0
    $graphics_buffer .= pack('n', 0);

}

# End a sequence of graphics commands by sending the entire buffer
sub graphics_end($)
{
    my ($self) = @_;
    
    $self->send($graphics_buffer); # Must ensure certain binary values are escaped
}

# Constants for creating graphics commands
my $PEN_X    = 0x0000;
my $PEN_Y    = 0x1000;
my $PEN_UP   = 0x0000;
my $PEN_DOWN = 0x0800;
# Screen coords are in rage 0 - 2047
# Y axis units are 3/4 size of the X axis units, need to divide Y coords by 0.75 to get correct aspect ratio
my $YSCALE = 0.75;

# Line style brightness
our $BRIGHTNESS_BLANK  = 0;
our $BRIGHTNESS_DIM    = 1;
our $BRIGHTNESS_HALF   = 2;
our $BRIGHTNESS_BRIGHT = 3;

# Line style line type
our $LINE_SOLID                 = 0;
our $LINE_INTENSIFIED_ENDPOINTS = 1;
our $LINE_LONG_DASHES           = 2;
our $LINE_SHORT_DASHES          = 3;

# Line writing speed
our $SPEED_20 = 0;  # 0.20 inches per us
our $SPEED_15 = 1;  # 0.15 inches per us
our $SPEED_10 = 2;  # 0.10 inches per us
our $SPEED_05 = 3;  # 0.05 inches per us

# Text size
our $SIZE_1_0 = 0;  # 1.0 x
our $SIZE_1_5 = 1;  # 1.5 x
our $SIZE_2_0 = 2;  # 2.0 x
our $SIZE_2_5 = 3;  # 2.5 x

# Text rotation (degrees antclockwise)
our $ROTATION_0 = 0;
our $ROTATION_90 = 1;
our $ROTATION_180 = 2;
our $ROTATION_270 = 3;

# Set the line style
sub graphics_line_style($$$$)
{
    my ($self, $brightness, $type, $speed) = @_;

    $brightness = $BRIGHTNESS_BRIGHT unless defined $brightness;
    $type = $LINE_SOLID unless defined $type;
    $speed = $SPEED_05 unless defined $speed;
    # Only 2 bits per value
    $brightness &= 0x3;
    $type &= 0x3;
    $speed &= 0x3;
    
    my $value = 0x6000 | ($brightness << 11) | ($type << 7) | ($speed << 3);
    $graphics_buffer .= pack('n', $value);
}

# Move pen without writing
sub graphics_moveto($$$)
{
    my ($self, $x, $y) = @_;

    $graphics_buffer .= pack('n', $PEN_X | $PEN_UP | ($x & 0x7ff));
    $graphics_buffer .= pack('n', $PEN_Y | $PEN_UP | ((int($y / $YSCALE) & 0x7ff)));
}

# Draw line from current position to new position
sub graphics_drawto($$$)
{
    my ($self, $x, $y) = @_;
    
    $graphics_buffer .= pack('n', $PEN_X | $PEN_UP   | ($x & 0x7ff));
    $graphics_buffer .= pack('n', $PEN_Y | $PEN_DOWN | ((int($y / $YSCALE) & 0x7ff)));
}

# Write a new polyline from the first pair of coordinates
sub graphics_polyline($@)
{
    my ($self, @line) = @_;

    $self->graphics_moveto(shift @line, shift @line);
    while (@line)
    {
	$self->graphics_drawto(shift @line, shift @line);
    }
}

# Write a single character at the current position with optional style
sub graphics_char($$$$)
{
    my ($self, $char, $size, $rotation) = @_;

    my $style = 0x00; # Use the previous
    # If $size or $rotation are defined, use them to establish a new style
    if (defined $size || defined $rotation)
    {
	$size &= 0x3;
	$rotation &= 0x3;
	$style |= $size << 3;
	$style |= $rotation << 1;
	$style |= 0x1; # Establish new size
    }
	
    $graphics_buffer .= pack('CC', 0x40 | $style, ord(substr($char, 0, 1))); # Only the value of the first char
}

# Write text at the current position with optional style
sub graphics_text($$$$)
{
    my ($self, $text, $size, $rotation) = @_;
    
    # First char to maybe establish style
    $self->graphics_char(substr($text, 0, 1, ''), $size, $rotation);
    while (length($text))
    {
	$self->graphics_char(substr($text, 0, 1, '')); # Each additional char in turn
    }
}

1;
