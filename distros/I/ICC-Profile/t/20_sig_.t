#!/usr/bin/perl -w

# ICC::Profile::sig_ test module / 2018-03-31
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use File::Temp;
use t::lib::Boot;
use Test::More tests => 6;

# local variables
my ($profile, $tag, $temp, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::sig_') };

# test class methods
can_ok('ICC::Profile::sig_', qw(new new_fh write_fh size text sdump));

# make empty sig_ object
$tag = ICC::Profile::sig_->new;

# test object class
isa_ok($tag, 'ICC::Profile::sig_');

# read sRGB_v4_ICC_preference profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'sRGB_v4_ICC_preference.icc'));

# read 'rig0' tag
$tag = ICC::Profile::sig_->new_fh($profile, $profile->fh, $profile->tag_table->[5]);

# test object class
isa_ok($tag, 'ICC::Profile::sig_');

# test size method
ok($tag->size == $profile->tag_table->[5][2], 'tag size');

# open temporary file for write-read access, binmode
$temp = File::Temp::tempfile();

# write tag to temporary file
$tag->write_fh($profile, $temp, $profile->tag_table->[5]);

# flush buffer
$temp->flush;

# read profile raw data
seek($profile->fh, $profile->tag_table->[5][1], 0);
read($profile->fh, $raw1, $tag->size);

# read temporary raw data
seek($temp, $profile->tag_table->[5][1], 0);
read($temp, $raw2, $tag->size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# close files
close($profile->fh);
close($temp);

##### more tests needed #####
