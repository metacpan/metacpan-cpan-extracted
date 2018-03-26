#!/usr/bin/perl -w

# ICC::Profile::bern test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::bern') };

# test class methods
can_ok('ICC::Support::bern', qw(new fit write_fh size inverse derivative transform header array roots table curv normalize sdump));

# make empty bern object
$tag = ICC::Support::bern->new;

# test object class
isa_ok($tag, 'ICC::Support::bern');

##### more tests needed ######


