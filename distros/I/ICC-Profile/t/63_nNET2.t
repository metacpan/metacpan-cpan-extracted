#!/usr/bin/perl -w

# ICC::Support::nNET2 test module / 2014-11-16
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::nNET2') };

# test class methods
can_ok('ICC::Support::nNET2', qw(new init fit header kernel hidden matrix offset add_kernel add_hidden transform inverse jacobian sdump));

# make empty nNET2 object
$tag = ICC::Support::nNET2->new;

# test object class
isa_ok($tag, 'ICC::Support::nNET2');

##### more tests needed ######

