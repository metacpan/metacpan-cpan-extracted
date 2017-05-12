#!/usr/bin/perl -w
use strict;
# use lib '../../';
use Debug::ShowStuff ':all';
use Test;

# NOTE: I'm not sure what6 to test.  Everything in this module is for
# outputting stuff, and I'm not sure how to test that. This script
# just tests that the module loads.

BEGIN { plan tests => 1 };

ok(1);
