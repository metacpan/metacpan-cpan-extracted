#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  00.load.t
#
#  DESCRIPTION:  Check that the Getopt::Auto module loads.
#                We don't go further here, as those tests require some magic.
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;

use 5.006;
our $VERSION = '1.9.8';

# use_ok( 'Getopt::Auto'). Interaction with Test::More results
# in execution errors if its not done in a BEGIN block.

BEGIN {
    if ( not use_ok('Getopt::Auto') ) {
        BAIL_OUT('Testing pointless if the module won\'t even load');
    }
}

diag("Testing Getopt::Auto $Getopt::Auto::VERSION");

exit 0;
