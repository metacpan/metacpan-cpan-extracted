#!/usr/bin/perl -w

# ICC::Profile::mpet test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use ICC::Profile::matf;
use ICC::Profile::curv;
use ICC::Profile::para;
use ICC::Profile::cvst;
use ICC::Profile::clut;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::mpet') };

# test class methods
can_ok('ICC::Profile::mpet', qw(new header array mask new_fh write_fh size cin cout transform inverse jacobian pcs wtpt sdump));

# make empty mAB_ object
$tag = ICC::Profile::mpet->new;

# test object class
isa_ok($tag, 'ICC::Profile::mpet');

##### more tests needed #####
