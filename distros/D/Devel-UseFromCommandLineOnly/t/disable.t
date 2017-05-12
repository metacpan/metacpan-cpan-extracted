#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec::Functions qw(:ALL);
use lib (catdir($FindBin::Bin, "lib"));

use Test::More tests => 1;

use AVeryUnlikelyModuleName qw(disable_command_line_checks);

ok(1,"It works!");