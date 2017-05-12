#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use File::Redirect qw(mount);

mount( 'Simple', 
	{
		'file1' => 'file1',
		'file2' => 'file2',
	}, 
	'redirect:'
);

ok( 1, 'mount');

mount( 'Simple', 
	{
		'file3' => 'file3',
		'file4' => 'file4',
	}, 
	'redirect2:'
);

ok( 1, 'another mount');

ok( open(F, 'redirect:file1'), 'opened existing file1');
ok( close(F), 'close opened handle');

ok( open(F, 'redirect2:file3'), 'opened existing file3');
ok( close(F), 'close opened handle');

ok( !open(F, 'redirect:file3'), 'opened non-existing file3');

ok( open(F, 'redirect:file1'), 'opened existing file1 again');
my $f = <F>;
ok( $f eq 'file1', 'file1 content is ok');

# DO NOT CLOSE THIS! Let's test global destruction
# close F;
