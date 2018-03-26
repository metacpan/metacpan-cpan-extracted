#!/usr/bin/perl -w

# ICC::Support::rbf test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::rbf') };

# test class methods
can_ok('ICC::Support::rbf', qw(new transform jacobian array center matrix sdump radius));

# make empty rbf object
$tag = ICC::Support::rbf->new;

# test object class
isa_ok($tag, 'ICC::Support::rbf');

##### more tests needed ######

