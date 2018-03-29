#!/usr/bin/perl -w

# ICC::Profile::mft1 test module / 2018-03-27
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use ICC::Profile::matf;
use ICC::Profile::curv;
use ICC::Profile::cvst;
use ICC::Profile::clut;
use Test::More tests => 6;

# local variables
my ($profile, $tag, $temp, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::mft1') };

# test class methods
can_ok('ICC::Profile::mft1', qw(new new_fh write_fh size cin cout header matrix input clut output mask clip transform inverse jacobian pcs wtpt sdump));

# make empty mft1 object
$tag = ICC::Profile::mft1->new;

# test object class
isa_ok($tag, 'ICC::Profile::mft1');

# read GRACoL2006_Coated1v2 profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'GRACoL2006_Coated1v2.icc'));

# read 'gamt' tag
$tag = ICC::Profile::mft1->new_fh($profile, $profile->fh, $profile->tag_table->[9]);

# test object class
isa_ok($tag, 'ICC::Profile::mft1');

# test size method
ok($tag->size == $profile->tag_table->[9][2], 'tag size');

# open temporary file for write-read access
open($temp, '+>' . File::Spec->catfile('t', 'data', 'temp.dat'));

# set binary mode
binmode($temp);

# write tag to temporary file
$tag->write_fh($profile, $temp, $profile->tag_table->[9]);

# read profile raw data
seek($profile->fh, $profile->tag_table->[9][1], 0);
read($profile->fh, $raw1, $tag->size);

# read temporary raw data
seek($temp, $profile->tag_table->[9][1], 0);
read($temp, $raw2, $tag->size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# close profile
close($profile->fh);

# close temporary file
close($temp);

##### more tests needed #####
