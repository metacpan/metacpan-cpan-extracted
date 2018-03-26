#!/usr/bin/perl -w

# ICC::Support::geo1 test module / 2014-11-15
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::geo1') };

# test class methods
can_ok('ICC::Support::geo1', qw(new transform jacobian points matrix sdump));

# make empty geo1 object
$tag = ICC::Support::geo1->new;

# test object class
isa_ok($tag, 'ICC::Support::geo1');

##### more tests needed ######

