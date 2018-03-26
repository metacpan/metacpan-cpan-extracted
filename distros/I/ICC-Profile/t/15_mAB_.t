#!/usr/bin/perl -w

# ICC::Profile::mAB_ test module / 2014-05-26
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
use Test::More tests => 6;

# local variables
my ($profile, $tag, $temp, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::mAB_') };

# test class methods
can_ok('ICC::Profile::mAB_', qw(new new_fh write_fh size cin cout header b_curves matrix m_curves clut a_curves mask clip transform inverse jacobian pcs wtpt sdump));

# make empty mAB_ object
$tag = ICC::Profile::mAB_->new;

# test object class
isa_ok($tag, 'ICC::Profile::mAB_');

# read sRGB_v4_ICC_preference profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'sRGB_v4_ICC_preference.icc'));

# read 'A2B0' tag
$tag = ICC::Profile::mAB_->new_fh($profile, $profile->fh, $profile->tag_table->[1]);

# test object class
isa_ok($tag, 'ICC::Profile::mAB_');

# test size method
ok($tag->size == $profile->tag_table->[1][2], 'tag size');

# open temporary file for write-read access
open($temp, '+>' . File::Spec->catfile('t', 'data', 'temp.dat'));

# write tag to temporary file
$tag->write_fh($profile, $temp, $profile->tag_table->[1]);

# read profile raw data
seek($profile->fh, $profile->tag_table->[1][1], 0);
read($profile->fh, $raw1, $tag->size);

# read temporary raw data
seek($temp, $profile->tag_table->[1][1], 0);
read($temp, $raw2, $tag->size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# close profile
close($profile->fh);

# close temporary file
close($temp);

##### more tests needed #####
