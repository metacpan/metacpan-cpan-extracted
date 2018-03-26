#!/usr/bin/perl -w

# ICC::Support::nNET test module / 2014-05-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::nNET') };

# test class methods
can_ok('ICC::Support::nNET', qw(new init fit header kernel matrix offset transform inverse jacobian sdump));

# make empty nNET object
$tag = ICC::Support::nNET->new;

# test object class
isa_ok($tag, 'ICC::Support::nNET');

##### more tests needed ######

