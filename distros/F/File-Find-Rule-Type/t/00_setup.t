#!/usr/bin/perl
use warnings;
use strict;

use lib './lib','../lib';
use Test::More tests => 2;

use File::Find::Rule::Type;

my $ft = File::Find::Rule::Type->new;

ok(defined $ft,             'new() returned something');
ok($ft->isa('File::Find::Rule::Type'),  "and it's the right class");
