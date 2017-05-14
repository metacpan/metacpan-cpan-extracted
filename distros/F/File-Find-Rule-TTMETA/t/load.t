#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Test::More;

plan tests => 2;

use_ok("File::Find::Rule::TTMETA");

use File::Find::Rule;

File::Find::Rule->import(":TTMETA");
ok(defined *{"File::Find::Rule::ttmeta"}, "File::Find::Rule->import(':TTMETA')");
