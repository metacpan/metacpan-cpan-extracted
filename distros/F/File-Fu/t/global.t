#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

is(File::Fu->program_name->relative, 't/global.t');
is(File::Fu->program_dir->relative, 't/');
is(File::Fu->THIS_FILE, 't/global.t');

# vim:ts=2:sw=2:et:sta
