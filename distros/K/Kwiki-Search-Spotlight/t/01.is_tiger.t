#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use File::Which qw(which);
use YAML;

my $uname = `uname`;

like($uname,qr/Darwin/);
my @path = which('mdfind');
ok(@path > 0);

