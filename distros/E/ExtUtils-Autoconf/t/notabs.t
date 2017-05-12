#!perl

use strict;
use warnings;
use Test::More;

eval 'use Test::NoTabs;';
plan skip_all => 'Needs Test::NoTabs' if $@;

plan tests => 10;
all_perl_files_ok(qw( lib t ));
