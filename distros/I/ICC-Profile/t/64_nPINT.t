#!/usr/bin/perl -w

# ICC::Support::nPINT test module / 2015-12-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Support::nPINT') };

# test class methods
can_ok('ICC::Support::nPINT', qw(new fit header pda array transform inverse jacobian sdump));

# make empty nPINT object
$tag = ICC::Support::nPINT->new;

# test object class
isa_ok($tag, 'ICC::Support::nPINT');

##### more tests needed ######

