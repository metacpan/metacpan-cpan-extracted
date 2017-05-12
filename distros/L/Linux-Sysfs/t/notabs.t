#!perl

use strict;
use warnings;

BEGIN {
    require 't/common.pl';
}

eval 'use Test::NoTabs;';
plan skip_all => 'Needs Test::NoTabs' if $@;

plan tests => 21;
all_perl_files_ok(qw( lib t ));
