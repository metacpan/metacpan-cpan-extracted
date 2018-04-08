#!/usr/bin/perl -w

# ICC::Profile::ZXML test module / 2018-03-31
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::ZXML') };

# test class methods
can_ok('ICC::Profile::ZXML', qw(new new_fh write_fh size data text sdump));

# make empty text object
$tag = ICC::Profile::ZXML->new;

# test object class
isa_ok($tag, 'ICC::Profile::ZXML');

##### more tests needed #####
