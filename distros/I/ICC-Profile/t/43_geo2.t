#!/usr/bin/perl -w

# ICC::Support::geo2 test module / 2014-11-15
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::geo2') };

# test class methods
can_ok('ICC::Support::geo2', qw(new transform jacobian points sdump));

# make empty geo2 object
$tag = ICC::Support::geo2->new;

# test object class
isa_ok($tag, 'ICC::Support::geo2');

##### more tests needed ######

