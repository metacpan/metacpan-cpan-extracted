#!/usr/bin/perl -w

# ICC::Profile::vcgt test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::vcgt') };

# test class methods
can_ok('ICC::Profile::vcgt', qw(new new_fh write_fh size array transform inverse sdump));

# make empty text object
$tag = ICC::Profile::vcgt->new;

# test object class
isa_ok($tag, 'ICC::Profile::vcgt');

##### more tests needed #####
