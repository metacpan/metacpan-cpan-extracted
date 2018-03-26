#!/usr/bin/perl -w

# ICC::Support::Color test module / 2016-05-06
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::Color') };

# test class methods
can_ok('ICC::Support::Color', qw(new header illuminant observer cwf iwtpt transform jacobian sdump));

# make empty Color object
$tag = ICC::Support::Color->new;

# test object class
isa_ok($tag, 'ICC::Support::Color');

##### more tests needed ######

