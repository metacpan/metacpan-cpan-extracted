#!/usr/bin/perl -w

# ICC::Profile::akima test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::akima') };

# test class methods
can_ok('ICC::Support::akima', qw(new write_fh size inverse derivative transform header array monotonic table curv normalize sdump));

# make empty akima object
$tag = ICC::Support::akima->new;

# test object class
isa_ok($tag, 'ICC::Support::akima');

##### more tests needed ######


