#!/usr/bin/perl
#
# hp3577.pl
#
# Control HP 3577A or 3577B 
#
# Plotting:
# Can use hp2xx to display the screen plot, or save to file:
# Note that the scale factor 1.7 produces something more closely resembling the screen
# whose pixels are not square
# Sigh, but hp2xx has a bug where if the first command is a LB label command, then hp2xx bails.
# The output from the GPIB PLA command starts with LB^C;
# so need to remove first 4 chars with:
# perl -I lib bin/hp3577.pl -plot | tail -c +5  | hp2xx -q -a 1.7 -
#
# Can use GPIB commands display text on the screen with ENA command:
# Clear the screen:
# perl -I lib bin/hp3577.pl 'IPR;ANC;AN1;TR1;DF0;GR0;CH0'
# Write some text on line 3:
# perl -I lib bin/hp3577.pl 'ENA"3Hello World!"'
# Can also use Device::GPIB::HP::HP3577A functions to write arbitrary vectors and
# text on the screen with the ENG command

use strict;
use Device::GPIB::Controller;
use Device::GPIB::HP::HP3577A;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the device
     'debug',               # Show debugging info like bytes in and out
     'lmo=s',               # Learn Mode Out: save instrument state to file
     'lmi=s',               # Learn Mode In: restore from previous LMO output
     'plot',                # Plot, emits HP-GL plot of the current screen to stdout
     'dky',                 # Print button and knob activity
     'file=s@'              # File(s) to read commands from
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 11;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);
exit unless $d;

my $na = Device::GPIB::HP::HP3577A->new($d, $address);
exit unless $na;

$d->clr();

$na->executeCommandsFromFiles(@main::opt_file);
$na->executeCommands(@ARGV);

if (defined $main::opt_lmo)
{
    # Save instrument state to file
    my $fh;
    open($fh, ">$main::opt_lmo") || die "could not open LMO output filename $main::opt_lmo: $!\n";
    binmode($fh);
    print $fh $na->lmo();
    close($fh);
}

if (defined $main::opt_lmi)
{
    # Restore instrument state from file
    my $fh;
    open($fh, "<$main::opt_lmi") || die "could not open LMI input filename $main::opt_lmi: $!\n";
    binmode($fh);
    my $state = <$fh>;
    $na->lmi($state);
    close($fh);
}

if (defined $main::opt_plot)
{
    my $hpgl = $na->sendAndRead('PLA'); # Plot All
    print $hpgl;
}

if (defined $main::opt_dky)
{
#    $na->sendAndRead('CKB'); # Clear keyboard buffer? 
    
    while (1)
    {
	my $dky =  $na->sendAndRead('DKY');
	if ($dky =~ /(\S+),\s*(\S+)/)
	{
	    my $key = int($1);
	    my $knob = int($2);
	    if ($key != -1 || $knob != 0)
	    {
		print "$key $knob\n";
	    }
	}
    }
}

# Test and example code for graphics mode
if (0)
{
    $na->graphics_clear();
    $na->graphics_start();
    $na->graphics_moveto(100, 100);
    $na->graphics_drawto(300, 200);
    $na->graphics_drawto(600, 700);
    $na->graphics_line_style(); # All defaults
    $na->graphics_line_style($Device::GPIB::HP::HP3577A::BRIGHTNESS_BRIGHT,
			     $Device::GPIB::HP::HP3577A::LINE_LONG_DASHES,
			     $Device::GPIB::HP::HP3577A::SPEED_05);

    $na->graphics_polyline(100, 100, 100, 1000, 1000, 1000, 1000, 100, 100, 100);

    $na->graphics_moveto(100, 100);
    $na->graphics_char("A"); # Use previous style
    $na->graphics_moveto(300, 300);
    $na->graphics_char("B", $Device::GPIB::HP::HP3577A::SIZE_2_5, $Device::GPIB::HP::HP3577A::ROTATION_0);

    $na->graphics_moveto(400, 400);
    $na->graphics_text("Wiseold Rocks!");
    $na->graphics_moveto(200, 200);
    $na->graphics_text("Wiseold Rocks!", $Device::GPIB::HP::HP3577A::SIZE_2_5, $Device::GPIB::HP::HP3577A::ROTATION_90);
    $na->graphics_end();
}

sub usage
{
    print "usage: $0 [-h]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
    	  -lmo filename                             Save instrument state to file
	  -lmi filename				    Load instrument state from file
	  -plot					    Plot screen using HP-GL to STDOUT
	  -dky					    Loop, printing key and knob activity
          [-file filename [-file filename]]         Send commands from file. Results of queries are printed
          \"commandstring;commandstring;...\"       Sends the commands to the device. 
	  \"commandstring;querystring?\"            Sends the optional commands and the query, prints the result of the query
\n";
    exit;
}
