#!/usr/bin/perl
use warnings;
use strict;

use lib './lib','../lib';
use Test::More tests => 4;

use File::Type;
use File::Type::Builder;

my $ft = File::Type->new();

ok(defined $ft,             'new() returned something');
ok($ft->isa('File::Type'),  "and it's the right class");

my $ftb = File::Type::Builder->new();

ok(defined $ftb,             'new() returned again');
ok($ftb->isa('File::Type::Builder'),  "and it's the right class again");

