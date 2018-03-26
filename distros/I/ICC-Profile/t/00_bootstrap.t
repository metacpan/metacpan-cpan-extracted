#!/usr/bin/perl -w

# t::lib::Boot test module / 2015-02-14
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use YAML::Tiny;
use Test::More tests => 6;

# local variables
my ($profile, $yaml);

# test if module loads
BEGIN { use_ok('t::lib::Boot') };

# test class methods
can_ok('t::lib::Boot', qw(new profile_header tag_table fh));

# read eciRGB_v2 profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'eciRGB_v2.icc'));

# test object class
isa_ok($profile, 't::lib::Boot');

# read eciRGB_v2 structure data
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'eciRGB_v2.yml'));

# test profile header
is_deeply($profile->profile_header, $yaml->[0], 'profile header');

# test tag table
is_deeply($profile->tag_table, $yaml->[1], 'tag table');

# test file handle
ok(ref($profile->fh) eq 'GLOB', 'file handle');

# close file
close($profile->fh);

