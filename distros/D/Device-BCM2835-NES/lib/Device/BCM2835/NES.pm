package Device::BCM2835::NES;

use 5.008005;
use strict;
use warnings;

use Exporter qw(import);

use Device::BCM2835 qw(
        BCM2835_GPIO_FSEL_INPT
        BCM2835_GPIO_FSEL_OUTP
		RPI_GPIO_P1_03
        RPI_GPIO_P1_05
        RPI_GPIO_P1_07
        RPI_GPIO_P1_08
        RPI_GPIO_P1_10
        RPI_GPIO_P1_11
        RPI_GPIO_P1_12
        RPI_GPIO_P1_13
        RPI_GPIO_P1_15
        RPI_GPIO_P1_16
        RPI_GPIO_P1_18
        RPI_GPIO_P1_19
        RPI_GPIO_P1_21
        RPI_GPIO_P1_22
        RPI_GPIO_P1_23
        RPI_GPIO_P1_24
        RPI_GPIO_P1_26
);

# Button constants
use constant {
	BTN_A      => 0x01,
	BTN_B      => 0x02,
	BTN_SELECT => 0x04,
	BTN_START  => 0x08,
	BTN_UP     => 0x10,
	BTN_DOWN   => 0x20,
	BTN_LEFT   => 0x40,
	BTN_RIGHT  => 0x80
};

our $VERSION     = '0.02';
our @EXPORT      = ();
our %EXPORT_TAGS = ( 
	'buttons' => [ 
		qw(
			BTN_A
			BTN_B
			BTN_SELECT
			BTN_START
			BTN_UP
			BTN_DOWN
			BTN_LEFT
			BTN_RIGHT
		)
	]
);

our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'buttons'} } );

# Holds the pin numbers of all controllers added with addController()
my $controllers = {};

sub new 
{
	my $class  = shift;
	my $latch  = shift || RPI_GPIO_P1_11;
	my $clock  = shift || RPI_GPIO_P1_12;
	
	my $ref = {
		'latch' => $latch,
		'clock' => $clock
	};
	
	bless($ref,$class);

	return $ref;
}

sub init
{
	my $this = shift;

	if (!Device::BCM2835::init()) {
		die("Could not intialize BCM2835 libraries.")
	}

	Device::BCM2835::gpio_fsel($this->{latch},BCM2835_GPIO_FSEL_OUTP);
	Device::BCM2835::gpio_fsel($this->{clock},BCM2835_GPIO_FSEL_OUTP);
	
	Device::BCM2835::gpio_clr($this->{latch});
	Device::BCM2835::gpio_clr($this->{clock});

	return 1;
}

sub addController
{
	my $this	= shift;
	my $pin		= shift;
		
	Device::BCM2835::gpio_fsel($pin,BCM2835_GPIO_FSEL_INPT);

	push(@{$this->{controllers}},$pin);

	return 1;
}

sub read
{
	my $this      = shift;

	# Toggle the latch 12us then wait 6us
	Device::BCM2835::gpio_set($this->{latch});
	Device::BCM2835::delayMicroseconds(12);
	Device::BCM2835::gpio_clr($this->{latch});
	Device::BCM2835::delayMicroseconds(6);

	my @value = (); # Will hold value of all buttons.
	my @tmp   = ();	# Temporary storage for button data.
	
	# Initialize arrays
	for (my $c = 0; $c < scalar(@{$this->{controllers}}); $c++) {
		push(@value,0);
		push(@tmp,0);
	}

	# Grab data from all eight buttons by pulsing the clock for 6us (12us for full pulse).

	for (my $i = 0; $i < 8; $i++) {
		
		for (my $c = 0; $c < scalar(@{$this->{controllers}}); $c++) {
			$tmp[$c] = Device::BCM2835::gpio_lev($this->{controllers}[$c]);
		}

		Device::BCM2835::gpio_set($this->{clock});
		Device::BCM2835::delayMicroseconds(6);
		
		Device::BCM2835::gpio_clr($this->{clock});
		Device::BCM2835::delayMicroseconds(6);
		
		for (my $c = 0; $c < scalar(@{$this->{controllers}}); $c++) {
			$value[$c] |= (!$tmp[$c] << $i);
		}
	}

	return @value;
}

sub translateButtons
{
	my $this     = shift;
	my $pressed  = shift;

	my @buttons  = ();

	if (($pressed & BTN_A) == BTN_A) {
		push(@buttons,"A");
	}
	if (($pressed & BTN_B) == BTN_B) {
		push(@buttons,"B");
	}
	if (($pressed & BTN_SELECT) == BTN_SELECT) {
		push(@buttons,"SELECT");
	}
	if (($pressed & BTN_START) == BTN_START) {
		push(@buttons,"START");
	}
	if (($pressed & BTN_UP) == BTN_UP) {
		push(@buttons,"UP");
	}
	if (($pressed & BTN_DOWN) == BTN_DOWN) {
		push(@buttons,"DOWN");
	}
	if (($pressed & BTN_LEFT) == BTN_LEFT) {
		push(@buttons,"LEFT");
	}
	if (($pressed & BTN_RIGHT) == BTN_RIGHT) {
		push(@buttons,"RIGHT");
	}

	return @buttons;
}

sub cycle
{
	my $this = shift;
	my $time = shift || ((1 / 60) * 1000);
	
	Device::BCM2835::delay($time);
}

1;
__END__

=head1 NAME

Device::BCM2835::NES - Perl extension for interfacing with a NES controller from the Raspberry Pi's GPIO ports.

=head1 SYNOPSIS

  # Sample Program (NOTE: MUST RUN VIA SUDO)

  use Device::BCM2835::NES;
  use strict;

  # Instantiate object
  my $nes = Device::BCM2835::NES->new();

  # Add controller at pin 21
  $nes->addController(Device::BCM2835::NES::RPI_GPIO_P1_13);

  # Initialize libraries / GPIO pins
  $nes->init();

  # Read contrller data
  while(1) {
	# Get raw data for all controllers
	my @raw = $nes->read();

	# Translate raw data into text (e.g SELECT, START)
	foreach $c (@raw) {
		my @btns = $nes->translateButtons($c);
		print join(' ',@btns);
	}

	# Cycle - NES Reads controller data at 60Hz
	$nes->cycle();
  }

=head1 DESCRIPTION

=head1 METHODS

=head2 new(['latch' => $latch, 'clock' => $clock])

	Instantiates new object and optionlly sets pins for CLOCK and LATCH pins.
	
	Defaults:
		LATCH - Device::BCM2835::NES::RPI_GPIO_P1_11
		CLOCK - Device::BCM2835::NES::RPI_GPIO_P1_12

=cut

=head2 init()

	Initialize BCM2835 libraries then clear latch and clock pins. 

=cut

=head2 addController($data_pin)    

	Adds a controller from which to read data.

=cut

=head2 read()

	Gets raw data from each of the controllers and returns them in an array.    

=cut

=head2 translateButtons($btn_data)

	Translate raw button data into text (e.g. 'A', 'SELECT')  

=cut

=head2 cycle([$time])    

	Delay between reads. NES polls at 60Hz by default.

=cut

=head1 SEE ALSO

L<http://search.cpan.org/~mikem/Device-BCM2835-1.3/lib/Device/BCM2835.pm>
L<http://www.mit.edu/~tarvizo/nes-controller.html>

=head1 AUTHOR

Chris Kloberdanz, E<lt>klobyone at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Chris Kloberdanz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
