#!/usr/bin/perl

# invoke this puppy by popping a 640 x 480 window
# and calling ./p_gen.cgi?hex=12ab87 to set the initial color
#
# p_gen.cgi
# version 1.04, 8-13-02
# Copyright, Michael Robinton, michael@bizsystems.com

use strict;
#use diagnostics;

use lib qw(./blib/lib);

require Graphics::ColorPicker;

#############################################
############## CONFIGURATION ################
#############################################

my $image_path	= './';		# must have trailing slash

#############################################
############ END CONFIGURATION ##############
#############################################

&Graphics::ColorPicker::make_page($image_path);
