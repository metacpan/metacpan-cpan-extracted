#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

# Test _use_
use_ok('Jar::Manifest') || BAIL_OUT('Failed to load Jar::Manifest');

# Done
done_testing();
exit 0;
