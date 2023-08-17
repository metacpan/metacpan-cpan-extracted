# Copyright (C) 2016-2023 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Test::More tests => 9;

use File::Globstar qw(globstar);

my $dir = __FILE__;
$dir =~ s{[-_a-zA-Z0-9.]+$}{globstar_star};
ok chdir $dir;

my @files = globstar '*.empty';
is_deeply [sort @files],
		  [('one.empty', 'three.empty', 'two.empty')];

@files = globstar '**';
is_deeply
	[sort @files],
	[qw (
		first.x
		first.x/one.empty
		first_x
		first_x/one.empty
		first_x/second
		first_x/second/one.empty
		first_x/second/third
		first_x/second/third/one.empty
		first_x/second/third/three.empty
		first_x/second/third/two.empty
		first_x/second/three.empty
		first_x/second/two.empty
		first_x/three.empty
		first_x/two.empty
		one.empty
		three.empty
		two.empty

	)];

@files = globstar '**/';
is_deeply
	[sort @files],
	[qw (
		first.x/
		first_x/
		first_x/second/
		first_x/second/third/
	)];

@files = globstar 'first_x/**';
is_deeply
	[sort @files],
		[qw (
			first_x/
			first_x/one.empty
			first_x/second
			first_x/second/one.empty
			first_x/second/third
			first_x/second/third/one.empty
			first_x/second/third/three.empty
			first_x/second/third/two.empty
			first_x/second/three.empty
			first_x/second/two.empty
			first_x/three.empty
			first_x/two.empty
		)];

@files = globstar 'first_x/**/';
is_deeply
	[sort @files],
	[qw (
		first_x/
		first_x/second/
		first_x/second/third/
	)];

@files = globstar 'first_x/**/*.empty';
is_deeply
	[sort @files],
	[qw (
		first_x/one.empty
		first_x/second/one.empty
		first_x/second/third/one.empty
		first_x/second/third/three.empty
		first_x/second/third/two.empty
		first_x/second/three.empty
		first_x/second/two.empty
		first_x/three.empty
		first_x/two.empty
	)];

@files = globstar '**/t*.*';
is_deeply
	[sort @files],
	[qw (
		first_x/second/third/three.empty
		first_x/second/third/two.empty
		first_x/second/three.empty
		first_x/second/two.empty
		first_x/three.empty
		first_x/two.empty
		three.empty
		two.empty
	)];

@files = globstar 'first_x/second/third/**';
is_deeply
	[sort @files],
	[qw(
		first_x/second/third/
		first_x/second/third/one.empty
		first_x/second/third/three.empty
		first_x/second/third/two.empty
	)];
