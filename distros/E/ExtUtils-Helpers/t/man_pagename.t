#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Config;
use File::Spec::Functions qw/catfile/;
use ExtUtils::Helpers qw/man1_pagename man3_pagename/;

my %separator = (
	MSWin32 => '.',
	VMS => '__',
	os2 => '.',
	cygwin => '.',
);
my $sep = $separator{$^O} || '::';

is man1_pagename('script/foo'), "foo.$Config{man1ext}", 'man1_pagename';

is man3_pagename(catfile(qw/lib ExtUtils.pm/)), "ExtUtils.$Config{man3ext}", 'man3_pagename 1';
is man3_pagename(catfile(qw/lib ExtUtils Helpers.pm/)), join($sep, qw/ExtUtils Helpers./).$Config{man3ext}, 'man3_pagename 2';
is man3_pagename(catfile(qw/lib ExtUtils Helpers Unix.pm/)), join($sep, qw/ExtUtils Helpers Unix./).$Config{man3ext}, 'man3_pagename 3';
