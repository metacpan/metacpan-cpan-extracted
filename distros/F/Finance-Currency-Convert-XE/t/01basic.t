#!/usr/bin/perl -w
use strict;

#########################

use Test::More tests => 1;

eval "use Finance::Currency::Convert::XE";
is($@,'');

#########################

