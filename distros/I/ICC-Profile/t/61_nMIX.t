#!/usr/bin/perl -w

# ICC::Support::nMIX test module / 2015-12-15
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::nMIX') };

# test class methods
can_ok('ICC::Support::nMIX', qw(new header array delta cin cout transform jacobian parajac sdump));

# make empty nMIX object
$tag = ICC::Support::nMIX->new;

# test object class
isa_ok($tag, 'ICC::Support::nMIX');

##### more tests needed ######

