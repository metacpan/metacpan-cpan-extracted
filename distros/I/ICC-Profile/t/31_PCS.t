#!/usr/bin/perl -w

# ICC::Support::PCS test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::PCS') };

# test class methods
can_ok('ICC::Support::PCS', qw(new clip linearity scale transform inverse jacobian tc_pars sdump));

# make empty PCS object
$tag = ICC::Support::PCS->new;

# test object class
isa_ok($tag, 'ICC::Support::PCS');

##### more tests needed ######

