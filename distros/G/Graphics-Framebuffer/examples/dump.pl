#!/usr/bin/env perl

# This is used as a diagnostic tool to send to the module author
# Use of Data::Dumper had to be removed due to segmentation faults... weird

use strict;
use constant {
	TRUE  => 1,
	FALSE => 0,
};
use utf8;
use open qw(:std :utf8);

use Term::ANSIColor;
use Data::Dumper;
eval { # Data::Dumper::Simple is preferred.  Try to load it without dying.
	require Data::Dumper::Simple;
	Data::Dumper::Simple->import();
	1;
};

# Set up dumper variables for friendly output

$Data::Dumper::Terse         = TRUE;
$Data::Dumper::Indent        = TRUE;
$Data::Dumper::Useqq         = TRUE;
$Data::Dumper::Deparse       = TRUE;
$Data::Dumper::Quotekeys     = TRUE;
$Data::Dumper::Trailingcomma = TRUE;
$Data::Dumper::Sortkeys      = TRUE;
$Data::Dumper::Purity        = TRUE;
$Data::Dumper::Deparse       = TRUE;

use Graphics::Framebuffer;

BEGIN {
    our $VERSION = '3.01';
}

our $fb = Graphics::Framebuffer->new('SHOW_ERRORS' => FALSE, 'RESET' => FALSE, 'SPLASH' => FALSE);
$fb->_screen_close();
delete($fb->{'START_SCREEN'}) if (exists($fb->{'START_SCREEN'}));
my $d = Dumper($fb);
undef($fb);
system('reset');

open (my $FILE,'>','dump.log');
binmode($FILE,':encoding(UTF-8)');
print $FILE colored(['red'],'Graphics') . colored(['green'],'::') . colored(['blue'],'Framebuffer') . " Diagnostics\n",'='x79,"\n";
print $FILE process($d);
print $FILE '='x79,"\n";
close($FILE);
exec('cat dump.log');

sub process {
	my $d = shift;
	my $rgb   = colored(['red'],'R')   . colored(['green'],'G') . colored(['blue'],'B');
	my $rbg   = colored(['red'],'R')   . colored(['blue'],'B')  . colored(['green'],'G');
	my $bgr   = colored(['blue'],'B')  . colored(['green'],'G') . colored(['red'],'R');
	my $brg   = colored(['blue'],'B')  . colored(['red'],'R')   . colored(['green'],'G');
	my $gbr   = colored(['green'],'G') . colored(['blue'],'B')  . colored(['red'],'R');
	my $grb   = colored(['green'],'G') . colored(['red'],'R')   . colored(['blue'],'B');
	my $red   = colored(['red'],'red');
	my $green = colored(['green'],'green');
	my $blue  = colored(['blue'],'blue');
	my $alpha = colored(['bright_yellow'],'alpha');
	my $RED   = colored(['red'],'RED');
	my $GREEN = colored(['green'],'GREEN');
	my $BLUE  = colored(['blue'],'BLUE');
	my $ALPHA = colored(['bright_yellow'],'ALPHA');
	my $fbd   = colored(['cyan'],'FB_DEVICE');
	$d =~ s/RGB/$rgb/g;
	$d =~ s/RBG/$rbg/g;
	$d =~ s/BGR/$bgr/g;
	$d =~ s/BRG/$brg/g;
	$d =~ s/GBR/$gbr/g;
	$d =~ s/GRB/$grb/g;
	$d =~ s/red/$red/g;
	$d =~ s/green/$green/g;
	$d =~ s/blue/$blue/g;
	$d =~ s/alpha/$alpha/g;
	$d =~ s/RED/$RED/g;
	$d =~ s/GREEN/$GREEN/g;
	$d =~ s/BLUE/$BLUE/g;
	$d =~ s/ALPHA/$ALPHA/g;
	$d =~ s/FB_DEVICE/$fbd/g;
	return($d);
}

=head1 NAME

Framebuffer Diagnostics Dump

=head1 DESCRIPTION

This script is used to help the author diagnose (and fix) any problems you may be having with the Graphics::Framebuffer module.  It finds all available framebuffers.

It creates a file called B<dump.log> in the same directory.  Please send this file as requested by the author.

=head1 SYNOPSIS

 perl dump.pl

=cut
