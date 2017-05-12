#!/usr/bin/perl

# invoke this puppy by popping a 640 x 480 window
# and calling ./p_gen.cgi?hex=12ab87 to set the initial color
#
# p_genw.cgi
# version 1.00, 3-25-12
# Copyright, Michael Robinton, michael@bizsystems.com

use strict;
#use diagnostics;

use lib qw(./blib/lib);

use Graphics::ColorPicker;


#############################################
############## CONFIGURATION ################
#############################################

my $image_path	= './images/';		# must have trailing slash
my $btxt = [
	'set_Text'	=> 'javascript:void(0);" OnMouseDown="top.setText(self);',
	'','',
	'set_Back'	=> 'javascript:void(0);" OnMouseDown="top.setBack(self);',
];
&Graphics::ColorPicker::buttontext($btxt);

#############################################
############ END CONFIGURATION ##############
#############################################

&Graphics::ColorPicker::make_page($image_path);
