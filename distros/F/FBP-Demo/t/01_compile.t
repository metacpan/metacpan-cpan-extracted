#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Script;

use_ok('FBP::Demo');

script_compiles('script/fbpdemo');
