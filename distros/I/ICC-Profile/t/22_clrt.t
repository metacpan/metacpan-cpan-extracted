#!/usr/bin/perl -w

# ICC::Profile::clrt test module / 2018-03-31
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 6;

# local variables
my ($clrt1, $channel, @all);

# test if module loads
BEGIN { use_ok('ICC::Profile::clrt') };

# test class methods
can_ok('ICC::Profile::clrt', qw(new new_fh write_fh size channel sdump));

# create new clrt object
$clrt1 = ICC::Profile::clrt->new();

# test clrt object class
isa_ok($clrt1, 'ICC::Profile::clrt');

# add colorant table
$clrt1->[1]  = [
	['cyan', 54.96, -37.12, -50.00],
	['magenta', 47.93, 74.11, -3.01],
	['yellow', 88.94, -5.02, 93.17],
	['black', 14.95, 0.19, -0.14]
];

# get single colorant channel
$channel = $clrt1->channel(0);

# test colorant info
is_deeply($channel, ['cyan', 54.96, -37.12, -50.00], 'clrt get channel 0');

# get all colorant channels
@all = $clrt1->channel(0, 1, 2, 3);

# test colorant info
is_deeply(\@all, $clrt1->[1], 'clrt get all channels');

# test size method
ok($clrt1->size == (12 + 38 * 4), 'clrt size');

##### more tests needed #####


