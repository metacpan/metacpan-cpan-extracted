#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Cwd;

use lib 'lib';
local $ENV{PERL5LIB} = cwd().'/lib';

use autodie qw(:all);

system('rm -rf tfiles');
mkdir 'tfiles';
system('cp -r xt/packages/version-from-changelog tfiles/x');

system('cd tfiles/x && dzil build >>../build.log');
ok(-d 'tfiles/x/X-0.01', 'version parsed from changelog correctly');

