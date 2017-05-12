package Device::BCM2835::LCD;

use 5.006;
use strict qw(vars);
use warnings;
use Carp;
use Device::BCM2835;
use Time::HiRes qw(usleep nanosleep);

=head1 NAME

Device::BCM2835::LCD - Perl extension for driving an HD44780 LCD from a Raspberry Pi's GPIO port

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Device::BCM2835::LCD;

    # Init display, specifying the GPIO pin connections 
    my $foo = Device::BCM2835::LCD->new();
    $foo->init(  
	Display => 2004,
	RPI_PIN => V2,
        pin_rs => RPI_GPIO_P1_24,
        pin_e => RPI_GPIO_P1_23,
        pin_d4 => RPI_GPIO_P1_07,
        pin_d5 => RPI_GPIO_P1_11,
        pin_d6 => RPI_GPIO_P1_13,
        pin_d7 => RPI_GPIO_P1_15
	);
   
     # print text to the screen 
     $foo->PutMsg("Hello");	
     # move cursor to line 2, col 0
     $foo->SetPos(2,0);
     # print text on second line
     $foo->PutMsg("world!");

     # Clear the LCD screen
     $foo->ClearDisplay;

     # bignums - position, number
     # display "123"
     $foo->BigNum(0,1);
     $foo->BigNum(1,2);
     $foo->BigNum(2,3);	

=head1 SUBROUTINES/METHODS

=head2 new

=cut

=head2 init([pin_rs => $pin], [pin_e => $pin], [pin_d4 => $pin] .. [pin_d7 => $pin], [RPI_PIN => V1] )

Initialises the LCD display, using either the default wiring arrangement or the pins specified with init().
RPI_PIN refers to the P1 header GPIO mapping scheme. 
Early boards use 'V1', B+ and revision 2 boards use RPI_PIN V2. The default is V2 pinout.

Default wiring is:
	pin_rs => RPI_GPIO_P1_24
        pin_e => RPI_GPIO_P1_23
        pin_d4 => RPI_GPIO_P1_07
        pin_d5 => RPI_GPIO_P1_11
        pin_d6 => RPI_GPIO_P1_13
        pin_d7 => RPI_GPIO_P1_15
	RPI_PIN => V2
=cut

=head2 SetPos(line,column)

       	Moves the cursor to the specified position.
	The top/left position of a 20x4 LCD is (1,0),
	with the bottom/right being (4,19)
=cut

=head2 ClearDisplay

	Clears all characters from the display
=cut

=head2 PutMsg($msg)

	writes the string $msg to the display starting
	at the current cursor position.
	Note that a 4 line display will wrap line 1 to 3, and 2 to 4.
=cut

=head2 Delay($milliseconds)

	Delay for $milliseconds ms. 
=cut

=head2 BigNum($position,$digit)
	
	Displays $digit in 4x4 large font at position $position.
	A 20x4 display has 5 positions (0-4), a 16x4 display has 4.
	This will only work with 4 line displays.
=cut

=head2 cmd($instruction)

	Writes command $instruction to the display.
	Useful instructions are:
	cmd(1) - clear display
	cmd(8) - switch off display
	cmd(12) - switch on display
=cut

=head1 AUTHOR

Joshua Small, C<< <josh at festy.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-bcm2835-lcd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-BCM2835-LCD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::BCM2835::LCD


You can also look for information at:

=head2 * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-BCM2835-LCD>

=head2 * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-BCM2835-LCD>

=head2 * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-BCM2835-LCD>

=head2 * Search CPAN

L<http://search.cpan.org/dist/Device-BCM2835-LCD/>



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Joshua Small.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

# Display dimensions - display names are in common 4 digit COLROW format
# i.e. a 16x2 display is called 1602, 20x4 is 2004 etc.
# Not used for anything at the moment...
my %DisplayCols =
  qw(0801 8 0802 8 1601 16 1602 16 2001 20 2002 20 2004 20 4002 40);
my %DisplayRows = qw(0801 1 0802 2 1601 1 1602 2 2001 1 2002 2 2004 4 4002 2);

# Map RPI_GPIO_P1_xx to BCM GPIO number
# Device::BCM2835 is then passed the BCM GPIO numbers and not RPI_GPIO_*

# V1 board GPIO mapping:
my %RPI_PIN_V1 = qw(
  RPI_GPIO_P1_03 0
  RPI_GPIO_P1_05 1
  RPI_GPIO_P1_07 4
  RPI_GPIO_P1_08 14
  RPI_GPIO_P1_10 15
  RPI_GPIO_P1_11 17
  RPI_GPIO_P1_12 18
  RPI_GPIO_P1_13 21
  RPI_GPIO_P1_15 22
  RPI_GPIO_P1_16 23
  RPI_GPIO_P1_18 24
  RPI_GPIO_P1_19 10
  RPI_GPIO_P1_21 9
  RPI_GPIO_P1_22 25
  RPI_GPIO_P1_23 11
  RPI_GPIO_P1_24 8
  RPI_GPIO_P1_26 7
);

# V2 board GPIO mapping (3 pins changed from V1)
my %RPI_PIN_V2 = qw(
  RPI_GPIO_P1_03 2
  RPI_GPIO_P1_05 3
  RPI_GPIO_P1_07 4
  RPI_GPIO_P1_08 14
  RPI_GPIO_P1_10 15
  RPI_GPIO_P1_11 17
  RPI_GPIO_P1_12 18
  RPI_GPIO_P1_13 21
  RPI_GPIO_P1_15 27
  RPI_GPIO_P1_16 23
  RPI_GPIO_P1_18 24
  RPI_GPIO_P1_19 10
  RPI_GPIO_P1_21 9
  RPI_GPIO_P1_22 25
  RPI_GPIO_P1_23 11
  RPI_GPIO_P1_24 8
  RPI_GPIO_P1_26 7
);

my $debug = 0;

my $RPI_PIN;    # ref to pin map (V1 or V2)
my $rs;         # R/S line
my $e;          # EN
my $d4;         # Data bits 7-4
my $d5;         # (4 bit mode)
my $d6;
my $d7;

# Flag to indicate that BigNum CGRAM chars
# have already been loaded.
# Load on first call to BigNum, in case
# we don't want BigNums but have custom chars
my $CGRAM_loaded = 0;

# Column 0 address for each line of the display
# (*04 displays really use 2 lines, so order is 1-3-2-4)
my %LinePos = qw(1 128 2 192 3 148 4 212);

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    return bless {}, $class;
}

# set debug(1) to see a bunch
# or uninteresting stuff about
# line strobing and bit shifting...
sub debug {
    my $self = shift;
    $debug = shift;
}

# init: set up LCD lines.
# Defaults are the "common" GPIO pins, and 20x4 screen
sub init {
    my $self     = shift;
    my %defaults = qw(
      Display 2004
      pin_rs RPI_GPIO_P1_24
      pin_e RPI_GPIO_P1_23
      pin_d4 RPI_GPIO_P1_07
      pin_d5 RPI_GPIO_P1_11
      pin_d6 RPI_GPIO_P1_13
      pin_d7 RPI_GPIO_P1_15
      RPI_PIN V2
    );
    my %args = ( %defaults, @_ );

    # map the specified pins to actual BCM GPIO numbers

	
    if ($args{RPI_PIN} eq 'V1') { $RPI_PIN = \%RPI_PIN_V1;}
    else { $RPI_PIN = \%RPI_PIN_V2;}

    $rs      = $$RPI_PIN{ $args{pin_rs} };
    $e       = $$RPI_PIN{ $args{pin_e} };
    $d4      = $$RPI_PIN{ $args{pin_d4} };
    $d5      = $$RPI_PIN{ $args{pin_d5} };
    $d6      = $$RPI_PIN{ $args{pin_d6} };
    $d7      = $$RPI_PIN{ $args{pin_d7} };
    
    # debug info to show assigned pins and display size
    $debug && print "Display mode: $args{Display}\n";
    $debug && print "RS: $args{pin_rs} ($rs)\n E: $args{pin_e} ($e)\n";
    $debug && print "D4: $args{pin_d4} ($d4)\nD5: $args{pin_d5} ($d5)\n";
    $debug && print "D6: $args{pin_d6} ($d6)\nD7: $args{pin_d7} ($d7)\n";
    $debug
      && print
"Display dimensions: $DisplayCols{$args{Display}}x$DisplayRows{$args{Display}}\n";

    # Initialise the Device::BCM2835 module.
    # This is used for the underlying direct GPIO
    # access, and the short delays
    # Returns 1 on success
    Device::BCM2835::init()
      || croak "Could not init Device::BCM2835 library\n";

    # set assigned pins to output mode
    Device::BCM2835::gpio_fsel( $rs, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );
    Device::BCM2835::gpio_fsel( $e,  &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );
    Device::BCM2835::gpio_fsel( $d4, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );
    Device::BCM2835::gpio_fsel( $d5, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );
    Device::BCM2835::gpio_fsel( $d6, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );
    Device::BCM2835::gpio_fsel( $d7, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP );

    # quick sanity test -
    # if we can't change the state of the RS line,
    # we're not going to get very far...

    my $rslevel = Device::BCM2835::gpio_lev($rs);
    if ( $rslevel == 0 ) {
        Device::BCM2835::gpio_set($rs);
    }
    else {
        Device::BCM2835::gpio_clr($rs);
    }
    my $newrslevel = Device::BCM2835::gpio_lev($rs);
    if ( $rslevel == $newrslevel ) {
        croak("GPIO error: pin access test failed.\n");
    }

    # end of sanity test

    # initialise the device in 4 bit mode
    # During this phase of display init there's
    # some specific timing requirements,
    # so can't use generic cmd()s...
    $self->delay(40);    # wait 40ms for screen to power-up
                         # I really don't think this is necessary
                         # considering how long it takes to boot
                         # the R-Pi...
    Device::BCM2835::gpio_write( $rs, 0 );    # cmd mode
    Device::BCM2835::gpio_write( $e,  0 );    # start with EN low
    nibbleToLines(3);                         # high nibble 0x03
    &strobe_E;                                # strobe EN
    usleep(4100);
    nibbleToLines(3);                         # low nibble 0x03
    &strobe_E;                                # strobe EN
    usleep(200);
    nibbleToLines(3);                         # high nibble 0x03
    &strobe_E;                                # strobe EN
    usleep(200);
    nibbleToLines(2);                         # low nibble 0x02, 4 bit mode
    &strobe_E;                                # strobe EN
    $self->delay(8);

    # screen is initialised, all timings should be
    # uniform so now switch to cmd() for rest of setup

    # set interface to 4 bit, 2 line
    $self->cmd(0x28);

    # set cursor style
    $self->cmd(0x08);

    # set cursor pos to home
    $self->cmd(0x01);

    # set cursor direction
    $self->cmd(0x06);

    # finally, turn on display
    $self->cmd(0x0c);

}

# strobe_E - pulses the EN pin to tell the
# display to load data on GPIO pins
sub strobe_E {
    Device::BCM2835::gpio_write( $e, 1 );
    Device::BCM2835::gpio_write( $e, 0 );
}

sub delay {
    my $self    = shift;
    my $delaymS = $_[0];
    usleep( $delaymS * 1000 );
}

# Takes 4 bits and writes them
# to the display's data lines 7-4
sub nibbleToLines {
    my $nibble = shift;
    Device::BCM2835::gpio_write( $d7, ( $nibble & 8 ) );
    Device::BCM2835::gpio_write( $d6, ( $nibble & 4 ) );
    Device::BCM2835::gpio_write( $d5, ( $nibble & 2 ) );
    Device::BCM2835::gpio_write( $d4, ( $nibble & 1 ) );
    $debug && print "Nibble: $nibble\n";
}

# instruction byte (rs = low)
# cmd(instruction) sends a single HD44780 instruction
# to the display's controller
sub cmd {
    my $self = shift;
    my $byte = $_[0];
    $debug && print "instruction cmd was $byte\n";
    my $hi = ( $byte & 0xF0 ) >> 4;
    my $lo = ( $byte & 0x0F );
    Device::BCM2835::gpio_write( $rs, 0 );
    nibbleToLines($hi);
    strobe_E;
    nibbleToLines($lo);
    strobe_E;
    if ( $byte < 3 ) { usleep(1500); }
}

# PutChar - write a single character to the
# display at the current cursor position
sub PutChar {
    my $self = shift;
    my $byte = $_[0];
    $debug && print "Char cmd was $byte\n";
    my $hi = ( $byte & 0xF0 ) >> 4;
    my $lo = ( $byte & 0x0F );
    Device::BCM2835::gpio_write( $rs, 1 );
    nibbleToLines($hi);
    strobe_E;
    nibbleToLines($lo);
    strobe_E;
}

# PutMsg - writes a string of characters to the
# display starting at the current position
sub PutMsg {
    my $self  = shift;
    my $msg   = $_[0];
    my @chars = split //, $msg;
    foreach my $char (@chars) {
        $self->PutChar( ord($char) );
    }
}

# SetPos(line,column) - moves the cursor to
# the requested position
sub SetPos {
    my $self     = shift;
    my $pos_line = $_[0];
    my $pos_col  = $_[1];
    my $PosCmd   = $LinePos{$pos_line} + $pos_col;
    $debug && print "Moving cursor to $pos_line:$pos_col ($PosCmd)\n";
    $self->cmd($PosCmd);
}

sub ClearDisplay {
    my $self = shift;
    $self->cmd(0x01);
}

sub LoadCGRAM {
    my $self = shift;

    # small block bottom left
    # Small Block on bottom right
    # small block bottom full
    # small block top left
    # small block top right
    # small block top full
    # decimal dot

    my @cgdata = (
        [ 0,  0,  0,  0,  3,  15, 15, 31 ],
        [ 0,  0,  0,  0,  31, 31, 31, 31 ],
        [ 0,  0,  0,  0,  24, 30, 30, 31 ],
        [ 31, 15, 15, 3,  0,  0,  0,  0 ],
        [ 31, 30, 30, 24, 0,  0,  0,  0 ],
        [ 31, 31, 31, 31, 0,  0,  0,  0 ],
        [ 0,  0,  0,  14, 14, 14, 12, 8 ]

        #[14,14,14,14,12,8,0,0]
    );

    for ( my $cgchar = 0 ; $cgchar < 7 ; $cgchar++ ) {
        my $shiftchar = ( $cgchar + 1 ) << 3;
        for ( my $cgline = 0 ; $cgline < 8 ; $cgline++ ) {
            $self->cmd( 0x40 | $shiftchar | $cgline );
            $self->PutChar( $cgdata[$cgchar][$cgline] );
        }
    }
    $CGRAM_loaded = 1;
}

sub BigNum {
    my $self   = shift;
    my $numpos = $_[0] * 4;
    unless ($CGRAM_loaded) {
        $self->LoadCGRAM;
    }

    my $numToPrint = $_[1];
    unless ( $numToPrint =~ m/[0-9.]/ ) { $numToPrint = 0; }
    if ( $numToPrint eq '.' ) {
        $self->SetPos( 4, ( $numpos - 1 ) );
        $self->PutChar(7);
        return;
    }
	$self->SetPos( 4, ( $numpos - 1 ) );
	$self->PutChar(254);

    my @big4_1 = (
        1, 2, 3, 0,   2,   3, 254, 0, 1, 2, 3, 0, 1, 2,
        3, 0, 2, 254, 254, 0, 2,   2, 2, 0, 1, 2, 3, 0,
        2, 2, 2, 0,   1,   2, 3,   0, 1, 2, 3, 0
    );
    my @big4_2 = (
        255, 254, 255, 0, 254, 255, 254, 0, 1,   2,   255, 0, 254, 2,
        255, 0,   255, 2, 2,   0,   255, 2, 2,   0,   255, 2, 3,   0,
        254, 2,   255, 0, 255, 2,   255, 0, 255, 254, 255, 0
    );
    my @big4_3 = (
        255, 254, 255, 0,   254, 255, 254, 0,   255, 254, 254, 0,   254, 254,
        255, 0,   254, 255, 254, 0,   254, 254, 255, 0,   255, 254, 255, 0,
        254, 255, 254, 0,   255, 254, 255, 0,   4,   6,   255, 0
    );
    my @big4_4 = (
        4,   6, 5,   0, 6,   6, 6, 0, 4,   6,   6, 0, 4, 6,
        5,   0, 254, 6, 254, 0, 6, 6, 5,   0,   4, 6, 5, 0,
        254, 6, 254, 0, 4,   6, 5, 0, 254, 254, 6, 0
    );

    $self->cmd( 0x80 + $numpos );
    $self->PutChar( $big4_1[ ( $numToPrint * 4 ) + 0 ] );
    $self->PutChar( $big4_1[ ( $numToPrint * 4 ) + 1 ] );
    $self->PutChar( $big4_1[ ( $numToPrint * 4 ) + 2 ] );

    $self->cmd( 0xc0 + $numpos );
    $self->PutChar( $big4_2[ ( $numToPrint * 4 ) + 0 ] );
    $self->PutChar( $big4_2[ ( $numToPrint * 4 ) + 1 ] );
    $self->PutChar( $big4_2[ ( $numToPrint * 4 ) + 2 ] );

    $self->cmd( 0x94 + $numpos );
    $self->PutChar( $big4_3[ ( $numToPrint * 4 ) + 0 ] );
    $self->PutChar( $big4_3[ ( $numToPrint * 4 ) + 1 ] );
    $self->PutChar( $big4_3[ ( $numToPrint * 4 ) + 2 ] );

    $self->cmd( 0xD4 + $numpos );
    $self->PutChar( $big4_4[ ( $numToPrint * 4 ) + 0 ] );
    $self->PutChar( $big4_4[ ( $numToPrint * 4 ) + 1 ] );
    $self->PutChar( $big4_4[ ( $numToPrint * 4 ) + 2 ] );

}

1;    # End of Device::BCM2835::LCD
