#!/usr/bin/perl -w

# ICC::Profile::clut test module / 2015-12-29
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::clut') };

# test class methods
can_ok('ICC::Profile::clut', qw(new header array gsa udf clut new_fh write_fh size cin cout build transform inverse jacobian sdump));

# make empty clut object
$tag = ICC::Profile::clut->new;

# test object class
isa_ok($tag, 'ICC::Profile::clut');

##### more tests needed ######

# see file '05_nCLUT.t' for tests of similar replaced module.

