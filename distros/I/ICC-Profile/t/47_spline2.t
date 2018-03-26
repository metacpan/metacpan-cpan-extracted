#!/usr/bin/perl -w

# ICC::Profile::spline2 test module / 2017-06-11
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::spline2') };

# test class methods
can_ok('ICC::Support::spline2', qw(new write_fh size transform inverse derivative parametric header range array monotonic table curv normalize sdump));

# make empty spline2 object
$tag = ICC::Support::spline2->new;

# test object class
isa_ok($tag, 'ICC::Support::spline2');

##### more tests needed ######


