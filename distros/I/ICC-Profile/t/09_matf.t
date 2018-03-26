#!/usr/bin/perl -w

# ICC::Profile::matf test module / 2016-05-18
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::matf') };

# test class methods
can_ok('ICC::Profile::matf', qw(new bradford cat02 fit header matrix offset primary transform inverse jacobian invsqr inv size cin cout sdump));

# make empty matf object
$tag = ICC::Profile::matf->new;

# test object class
isa_ok($tag, 'ICC::Profile::matf');

##### more tests needed ######

