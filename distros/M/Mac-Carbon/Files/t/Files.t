#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib "../blib/arch";
use lib "../blib/lib";

BEGIN { plan tests => 52 }

use File::Basename;
use File::Spec::Functions qw(catdir catfile splitdir tmpdir);
use Mac::Files;
use MacPerl 'MakePath';

my(@rm_files, @rm_dirs);

END {
	unlink @rm_files;
	rmdir for reverse @rm_dirs;
}

SKIP: {
#	skip "Mac::Files", 52;

	# 0
	my $dir = tmpdir();

	# 0
	my $dir1  = catdir($dir, "f" . ("o" x 30));
	my $file1 = catdir($dir1, "a");
	push @rm_dirs,  $dir1;
	push @rm_files, $file1;
	my($type, $creator, $creator1) = ('TEXT', 'R*ch', 'MPS ');


	ok(FSpDirCreate($dir1),                                      "FSpDirCreate: $dir");
	ok(-d $dir1,                                                 "dir exists");
	ok(FSpCreate($file1, $creator, $type),                       "FSpCreate");
	ok(-f $file1,                                                "file exists");

	# 4
	ok(my $ci    = FSpGetCatInfo($dir1),                         "FSpGetCatInfo");
	ok(my $file2 = FSMakeFSSpec($ci->ioVRefNum, $ci->ioDrDirID, "b"), "FSMakeFSSpec");
	push @rm_files, MakePath($file2);
	ok(FSpCreate($file2, $creator, $type),                       "FSpCreate");
	ok(-f MakePath($file2),                                      "file exists");

	# 8
	my @stat = stat $dir1;
	my $ntime = time + 3600;
	my $x = $ci->ioDrMdDat;
	my $y = $stat[9];
	ok( (($x == $y) || ($x == $y + 1) || ($x == $y - 1)),        "check ioDrMdDat");
	ok($ci->ioDrMdDat($ntime),                                   "set ioDrMdDat");
	ok(FSpSetCatInfo($dir1, $ci),                                "FSpSetCatInfo");

	ok($ci = FSpGetCatInfo($dir1),                               "FSpGetCatInfo");
	@stat = stat $dir1;
	$x    = $ci->ioDrMdDat;
	$y    = $stat[9];
	my $z = $ntime;
	ok( (($x == $y) || ($x == $y + 1) || ($x == $y - 1)),        "check ioDrMdDat");
	ok( (($x == $z) || ($x == $z + 1) || ($x == $z - 1)),        "check ioDrMdDat");

	# 14
	ok(my $fi = FSpGetFInfo($file1),                             "FSpGetFInfo");
	is($fi->fdType, $type,                                       "check fdType");
	is($fi->fdCreator, $creator,                                 "check fdCreator");
	ok($fi->fdCreator($creator1),                                "set fdCreator");
	ok(FSpSetFInfo($file1, $fi),                                 "FSpSetFInfo");
	ok($fi = FSpGetFInfo($file1),                                "FSpGetFInfo");
	is($fi->fdCreator, $creator1,                                "check fdCreator");

	# 21
	ok($ci = FSpGetCatInfo($file1),                              "FSpGetCatInfo");
	is($ci->ioFlAttrib & kioFlAttribLocked, 0,                   "! kioFlAttribLocked");
	ok(FSpSetFLock($file1),                                      "FSpSetFLock");
	ok($ci = FSpGetCatInfo($file1),                              "FSpGetCatInfo");
	is($ci->ioFlAttrib & kioFlAttribLocked, 1,                   "kioFlAttribLocked");
	ok(FSpRstFLock($file1),                                      "FSpRstFLock");
	ok($ci = FSpGetCatInfo($file1),                              "FSpGetCatInfo");
	is($ci->ioFlAttrib & kioFlAttribLocked, 0,                   "! kioFlAttribLocked");

	# 29
	my $file3 = catfile($dir1, "c");
	push @rm_files, $file3;
	ok(FSpRename($file1, "c"),                                   "FSpRename");
	ok(-e $file3,                                                "file exists");

	# 31
	my $dir2  = catdir($dir1, "f" . ("o" x 30));
	my $file4 = catfile($dir2, "c");
	push @rm_dirs,  $dir2;
	push @rm_files, $file4;
	ok(FSpDirCreate($dir2),                                      "FSpDirCreate");
	ok(-d $dir2,                                                 "dir exists");
	ok(FSpCatMove($file3, $dir2),                                "FSpCatMove");
	ok(-f $file4,                                                "file exists");

	# 35
	ok(open(my $fh1, ">", MakePath($file2)),                     "open file");
	ok(open(my $fh2, "> $file4"),                                "open file");
	ok(print($fh1 "foo\n"),                                      "print value");
	ok(print($fh2 "bar\n"),                                      "print value");
	ok(close($fh1),                                              "close file");
	ok(close($fh2),                                              "close file");

	ok(FSpExchangeFiles($file2, $file4),                         "FSpExchangeFiles");

	# 42
	ok(open($fh1, "<", MakePath($file2)),                        "open file");
	ok(open($fh2, "< $file4"),                                   "open file");
	is(scalar <$fh1>, "bar\n",                                   "check value");
	is(scalar <$fh2>, "foo\n",                                   "check value");
	ok(close($fh1),                                              "close file");
	ok(close($fh2),                                              "close file");

	# 48
	ok(FSpDelete($file2),                                        "FSpDelete");
	ok(!FSpDelete($file2),                                       "FSpDelete");
	ok(FSpDelete($file4),                                        "FSpDelete");
	ok(!FSpDelete($file4),                                       "FSpDelete");
}

#SKIP: {
#	skip "Mac::Files Unix2Mac", 1;

#	*Unix2Mac = *Mac::Files::_Unix2Mac{CODE};
#}

#SKIP: {
#	skip "Mac::Files misc.", 1;

	# UnmountVol
	# Eject
	# FlushVol
#}

__END__
