#!/usr/bin/perl -w

# ICC::Profile::ratfunc test module / 2017-06-11
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::ratfunc') };

# test class methods
can_ok('ICC::Support::ratfunc', qw(new header matrix fit transform cin cout sdump));

# make empty ratfunc object
$tag = ICC::Support::ratfunc->new;

# test object class
isa_ok($tag, 'ICC::Support::ratfunc');

##### more tests needed ######


