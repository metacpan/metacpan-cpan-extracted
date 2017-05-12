#!/usr/bin/perl

use strict;
use warnings;


#######################
# TESTING starts here #
#######################
use Test::More tests => 6;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Mhtml2Mobi';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, 'new');
can_ok($obj, 'debug_on');
can_ok($obj, 'debug_off');
can_ok($obj, 'pack');

# MORE TESTS WOULD BE QUITE COMPLICATE.
# YOU WOULD HAVE TO EXAMINE THE MOBI-FORMAT...

########
# done #
########
1;

