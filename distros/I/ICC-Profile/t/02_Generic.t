#!/usr/bin/perl -w

# ICC::Profile::Generic test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use Test::More tests => 4;

# local variables
my ($profile, $tag, $temp, $ttab, $size, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::Generic') };

# test class methods
can_ok('ICC::Profile::Generic', qw(new new_fh write_fh size data sdump));

# make empty Generic object
$tag = ICC::Profile::Generic->new;

# test object class
isa_ok($tag, 'ICC::Profile::Generic');

# read GRACoL2006_Coated1v2 profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'GRACoL2006_Coated1v2.icc'));

# open temporary file for write-read access
open($temp, '+>' . File::Spec->catfile('t', 'data', 'temp.dat'));

# for each tag table entry
for $ttab (@{$profile->tag_table}) {
	
	# read tag as Generic type
	$tag = ICC::Profile::Generic->new_fh($profile, $profile->fh, $ttab);
	
	# write tag to temporary file
	$tag->write_fh($profile, $temp, $ttab);
	
}

# compute total tag size
$size = $profile->tag_table->[-1][2] + $profile->tag_table->[-1][1] - $profile->tag_table->[0][1];

# read profile raw data
seek($profile->fh, $profile->tag_table->[0][1], 0);
read($profile->fh, $raw1, $size);

# read temporary raw data
seek($temp, $profile->tag_table->[0][1], 0);
read($temp, $raw2, $size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# close profile
close($profile->fh);

# close temporary file
close($temp);
