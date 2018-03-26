#!/usr/bin/perl -w

# ICC::Profile::gbd_ test module / 2015-04-05
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::gbd_') };

# test class methods
can_ok('ICC::Profile::gbd_', qw(new header vertex pcs device new_fh write_fh size sdump));

# make empty text object
$tag = ICC::Profile::gbd_->new;

# test object class
isa_ok($tag, 'ICC::Profile::gbd_');

##### more tests needed #####
