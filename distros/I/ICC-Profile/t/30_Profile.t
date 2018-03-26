#!/usr/bin/perl -w

# ICC::Profile test module / 2015-02-14
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use Test::More tests => 3;

# local variables
my ($profile);

# does module load
BEGIN { use_ok('ICC::Profile') };

# test class methods
can_ok('ICC::Profile', qw(new header profile_header tag_table tag write sdump));

# make empty Profile object
$profile = ICC::Profile->new();

# test object class
isa_ok($profile, 'ICC::Profile');

##### more tests needed #####

