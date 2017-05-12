#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Cwd;

use lib 'lib';
local $ENV{PERL5LIB} = cwd().'/lib';

use autodie qw(:all);

system('rm -rf tfiles');
mkdir 'tfiles';
system('cp -r xt/packages/x tfiles/');

system('cd tfiles/x && dzil debuild --us --uc >../x.build.log');

ok(-e 'tfiles/x/debuild/libx-perl_0.01_all.deb', '.deb file generated');

my $debc_result = qx(cd tfiles/x && dzil debc);

like($debc_result, qr{^\Qlibx-perl_0.01_all.deb
----------------------
 new debian package, version 2.0.}, 'dzil debc result looks like debc output');

