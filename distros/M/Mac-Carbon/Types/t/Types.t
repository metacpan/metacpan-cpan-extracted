#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 4 }

use Mac::Files;
use Mac::Types;
use MacPerl 'MakeFSSpec';

SKIP: {
#	skip "Mac::Types", 4;

	my $s = "Hello";
	my $p = MacPack("STR ", $s);
	is($p, (chr(length $s) . $s), 'pascal string');
	my $u = MacUnpack("STR ", "$p dskjkjkdsjk");
	is($u, $s, 'regular string');

	my $path = MakeFSSpec(FindFolder(kOnSystemDisk, kApplicationSupportFolderType));
	my $fss = MacPack('fss ', $path);
	isnt($path, $fss, 'to real FSSpec');
	is($path, MacUnpack('fss ', $fss), 'back to string FSSpec');
}

__END__
