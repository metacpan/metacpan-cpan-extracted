#!/usr/bin/perl

use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 7;

###########################
# General module tests... #
###########################

my $module = 'EPublisher::Target::Plugin::EPub';
use_ok( $module );
use_ok( 'EPublisher::Target::Base' );

my $obj = $module->new();

isa_ok($obj, 'EPublisher::Target::Base');

can_ok($obj, 'deploy');
can_ok($obj, 'new');
can_ok($obj, 'publisher');
can_ok($obj, '_config');

########
# done #
########
1;

