#!/usr/bin/perl
#
# tr4131.pl
#
# Advantest TR4131 series Spectrum Analyser
# Pulls the data from the TR4131 and synthesizes a screen image file
# Example usage:
# perl -I lib bin/tr4131.pl -port /dev/ttyUSB5 -precommands 'CF1GZ'
#
# Commands from https://www.advantest.com/global-services/ps/electronic-measuring/pdf/pdf_mn_ER4131_OPERATING_MANUAL.pdf

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Advantest::TR4131;
use Imager;

use Getopt::Long;

my @options =
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 0;
my $output_file = 'output.png';

$output_file = $ARGV[0] if defined $ARGV[0];

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $sa = Device::GPIB::Advantest::TR4131->new($d, $address);
exit unless $sa;

# Configure Prologix
# We dont want EOT chars sent to us
$d->eot_enable(0);

# Configure device
# Ensure we get no headers with values
# Get units from the mode
$sa->send('HD0');

# Default is line termination CR LF
# but this speeds things up, configure for CR, LF, EOI
$sa->send('DL0');

# Execute precommands
if (defined $main::opt_precommands)
{
    $sa->send($main::opt_precommands);
}

plot();

sub plot
{
    # Get display data
    # Mode string in binary (no CR/LF)
    my $om = $sa->sendAndRead('OM');

    # Some models also include AFC at end (but not the TR4131)
    my ($attenuator, $y_scale, $ref_units, $ref_fine, $trigger_mode, $cf_marker, $afc) = unpack("C C C C C C C", $om);
#    print "mode $attenuator, $y_scale, $ref_units, $ref_fine, $trigger_mode, $cf_marker, $afc\n";
    
    # Center frequency
    my $cf = $sa->sendAndRead('OPCF');
#    print "CF $cf\n";
    
    # Attentuator
    #my $at = $sa->sendAndRead('OPAT');
    #print "AT $at\n";
    
    # Reference level
    my $rl = $sa->sendAndRead('OPRL');
#    print "RL $rl\n";
    
    # Resolution bandwidth
    my $rb = $sa->sendAndRead('OPRB');
#    print "RB $rb\n";
    
    # Frequency span
    my $sp = $sa->sendAndRead('OPSP');
#    print "SP $sp\n";
    
    # Sweep time
    my $st = $sa->sendAndRead('OPST');
#    print "ST $st\n";
    
    my @data = $sa->readData();
#    print "screen: @data\n";
    
    # The TR4131 screen is 511 high and about 801 wide
    # graticule squares are 70 x 50
    # Graph origin is at 70, 70
    my $screen_width = 801;
    my $screen_height = 511;
    my $graph_x = 50;
    my $graph_y = 70;
    my $graph_width = 701;
    my $graph_height = 400;
    my $image = Imager->new(xsize => $screen_width, ysize => $screen_height);
    my $green = Imager::Color->new( 0, 255, 0 );
    my $magenta = Imager::Color->new( 255, 0, 255 );
    my $yellow = Imager::Color->new( 255, 255, 0 );
    
    # Graticule lines
    for (my $i = 0; $i < 11; $i++)
    {
	# Vertical graticule lines
	$image->line(color=>$green,
		     x1 => $graph_x + $i * 70, y1 => $screen_height - $graph_y,
		     x2 => $graph_x + $i * 70, y2 => $screen_height - $graph_y - $graph_height);
	# Horizontal graticule lines
	$image->line(color=>$green,
		     x1 => $graph_x, y1 => $screen_height - $graph_y - $i * 50,
		     x2 => $graph_x + $graph_width, y2 => $screen_height - $graph_y - $i * 50);
    }

    # Graph
    for (my $i = 0; $i < 700; $i++)
    {
	$image->line(color=>$magenta,
		     x1 => $graph_x + $i, y1 => $screen_height - $data[$i],
		     x2 => $graph_x + $i + 1, y2 => $screen_height - $data[$i + 1]);
    }

    my $font = Imager::Font->new(file  => '/usr/share/fonts/truetype/hack/Hack-Regular.ttf',
				 index => 0,
				 color => $yellow,
				 size  => 30,
				 aa    => 1);
    die "Could not load font" unless $font;
    
    # Attenuator setting
    my @attenuator_units_strings = ('0dB', '10dB', '20dB', '30dB', '40dB', '50dB');
    $image->align_string(color => $yellow,
			 x => $screen_width / 2, y => $screen_height - 10,
			 string => "ATT " . $attenuator_units_strings[$attenuator],
			 font => $font,
			 halign => 'center',
	);

    # Sweep time
    $image->align_string(color => $yellow,
			 x => 10, y => $screen_height - 10,
			 string => 'ST ' . $st * 1000 . 'ms/',
			 font => $font,
	);

    # Reference level
    my @ref_units_strings = ('dBm', 'dBu', 'dbUm(A)', 'dBum(B)', 'dBum(C)', 'dBum(D)', 'mV', 'dBmV');
    $image->align_string(color => $yellow,
			 x => 10, y => 30,
			 string => sprintf("%.0f%s", $rl, $ref_units_strings[$ref_units]),
			 font => $font,
	);

    # Center Frequency
    $image->align_string(color => $yellow,
			 x => $screen_width / 2, y => 30,
			 string => sprintf("%.3fMHz", $cf / 1000000),
			 font => $font,
			 halign => 'center',
	);
    
    # Span per division
    $image->align_string(color => $yellow,
			 x => $screen_width - 10, y => 30,
			 string => sprintf("%.0fMHz", $sp / 1000000),
			 font => $font,
			 halign => 'right',
	);

    # Vertical axis scale
    my @y_scale_units = ('10dB/', '2dB/', '5dB/ (QP)', 'LINEAR');
    $image->align_string(color => $yellow,
			 x => $screen_width - 10, y => 70,
			 string => $y_scale_units[$y_scale],
			 font => $font,
			 halign => 'right',
	);
    # Resolution bandwidth
    $image->align_string(color => $yellow,
			 x => $screen_width - 10, y => 110,
			 string => sprintf("%.0fkHzw", $rb / 1000),
			 font => $font,
			 halign => 'right',
	);
    
    # Output the file
    $image->write(file => $output_file)
	or die "Cannot save file: $output_file", $image->errstr;
    print "Wrote $output_file\n";
}

sub usage
{
    print "usage: $0 [-h] 
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
          [-precommands gpibcommandstring]
	  [filename]      (default: ouput.png)\n";
    exit;
}
