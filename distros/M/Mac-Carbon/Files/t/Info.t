#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 14 }

use File::Spec::Functions qw(catfile);
use Mac::Files;

SKIP: {
#	skip "Mac::Files Info", 16;

	# 0
	ok(my $dir = FindFolder(kOnSystemDisk, kFontsFolderType),    "FindFolder");
	like($dir, qr/Fonts/,                                        "Check name");
	ok(-d $dir,                                                  "Is a folder");

	# 3
	ok(my $catinfo = FSpGetCatInfo($dir),                        "CatInfo");
	ok(my $dinfo = $catinfo->ioDrUsrWds,                         "DInfo");
	is($dinfo->frFlags & kIsInvisible, 0,                        "! kIsInvisible");

	opendir my $dh, $dir or die $!;
	my $file;
	my $index = 0;
	for (readdir $dh) {
		next if /^\.\.?$/;
		$index++;
		$file = $_, last if /^Geneva/;
	}
	closedir $dh;

	# 6
	ok($catinfo = FSpGetCatInfo(catfile($dir, $file)),           "CatInfo");
	ok(my $finfo = FSpGetFInfo(catfile($dir, $file)),            "FInfo");
	is($catinfo->ioFlFndrInfo->fdType,    $finfo->fdType,        "fdType");
	is($catinfo->ioFlFndrInfo->fdCreator, $finfo->fdCreator,     "fdCreator");
	is($catinfo->ioFlFndrInfo->fdFlags,   $finfo->fdFlags,       "fdFlags");
	is($finfo->fdFlags & kIsInvisible, 0,                        "! kIsInvisible");

	# 12
	ok($catinfo = FSpGetCatInfo($dir, $index),                   "CatInfo");
	is($catinfo->ioNamePtr, $file,                               "ioNamePtr");
}

__END__
