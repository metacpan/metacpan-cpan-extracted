#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 33;
use Test::Exception;

use File::Temp 'tempdir';
use File::Path 'mkpath';

BEGIN {
    use_ok ( 'File::is' ) or exit;
}

exit main();

sub main {
	# test _construct_filename()
	dies_ok { File::is::_construct_filename(); } 'die when no arg to _construct_filename()';
	is(
		File::is::_construct_filename('file'),
		'file',
		'_construct_filename() with one argument'
	);
	is(
		File::is::_construct_filename('folder', 'subfolder', 'file'),
		File::Spec->catfile('folder', 'subfolder', 'file'),
		'_construct_filename() with more argument'
	);
	is(
		File::is::_construct_filename([ 'folder', 'subfolder', 'file' ]),
		File::Spec->catfile('folder', 'subfolder', 'file'),
		'_construct_filename() with array ref argument'
	);
	
	# setup three files in different folders
	my $tfolder = tempdir( CLEANUP => 1 );
	my $tfolder1 = File::Spec->catdir($tfolder, 'sub', 'sub');
	mkpath($tfolder1);
	my $tfolder2 = File::Spec->catdir($tfolder, 'sub1', 'sub2');
	mkpath($tfolder2);
	my $tfolder3 = File::Spec->catdir($tfolder, 'sub3', 'sub4');
	mkpath($tfolder3);
	my $fn1 = File::Spec->catfile($tfolder1, 'f1');
	my $fn2 = File::Spec->catfile($tfolder2, 'f2');
	my $fn3 = File::Spec->catfile($tfolder3, 'f3');
	diag 'three files ('.$fn1.', '.$fn2.', '.$fn3.')';
	open my $fh1, '>', $fn1;
	open my $fh2, '>', $fn2;
	open my $fh3, '>', $fn3;
	print $fh1 "hell world\n";
	print $fh2 "hell world\n";
	print $fh3 "hell world\n" x 3;
	close($fh1);close($fh2);close($fh3);
	
	# test newer
	ok(!File::is->newer($fn1, $fn2, $fn3), 'file1 was created as first cannot be newer');
	utime time(), time()-5, $fn1;
	utime time(), time()-10, $fn2;
	ok(!File::is->newer($fn1, $fn3), 'file1 still not never then file3');
	ok(!File::is->newer($fn1, [ $tfolder, 'sub3', 'sub4', 'f3' ]), 'file1 still not never then file3');
	ok(File::is->newer($fn1, $fn2), 'but newer than file2 ( time()-10 )');
	ok(File::is->newer([ $tfolder, 'sub', 'sub', '..', 'sub', 'f1' ], [ $tfolder, 'sub1', 'sub2', 'f2' ]), 'but newer than file2 ( time()-10 )');
	
	# test newest
	ok(File::is->newest($fn3, $fn2, $fn1), 'file2 is newset of them');
	ok(!File::is->newest($fn2, $fn1, $fn3), 'file3 is NOT newset of them');
	ok(!File::is->newest($fn1, $fn3, $fn2), 'file1 is NOT newset of them');

	# test older
	ok(File::is->older($fn2, $fn1), 'file2 is older then file1');
	ok(!File::is->older($fn3, $fn1), 'file3 not older than file1');

	# test oldest
	ok(File::is->oldest($fn2, $fn1, $fn3), 'file2 is oldest of them');
	ok(!File::is->oldest($fn3, $fn1, $fn2), 'file3 is NOT oldest of them');
	ok(!File::is->oldest($fn1, $fn3, $fn2), 'file1 is NOT oldest of them');

	# test die
	dies_ok { File::is->older($fn2, 'non-existing' ) } 'die with non existing file';

	# test similar, notlike
	my $time = time();
	utime $time, $time-5, $fn1;
	utime $time, $time-5, $fn2;
	utime $time, $time-5, $fn3;
	ok(File::is->similar($fn2, $fn1), 'file1 is similar to file2');
	ok(!File::is->similar($fn1, $fn3), 'file1 is not similar to file2');
	
	# test bigger, biggest
	ok(File::is->bigger($fn3, $fn1), 'file3 is bigger than file1');
	ok(!File::is->bigger($fn1, $fn3, $fn2), 'file2 is not bigger than file1 or file3');
	ok(File::is->biggest($fn3, $fn1, $fn2), 'file3 the biggest');
	ok(!File::is->biggest($fn1, $fn3, $fn2), 'file1 is not the biggest');
	
	# test smaller, smallest
	ok(File::is->smaller($fn1, $fn2, $fn3), 'file1 is smaller than file3');
	ok(!File::is->smaller($fn1, $fn2), 'file1 is not smaller than file2');
	ok(File::is->smallest($fn1, $fn3), 'file1 is the smallest when comparing just to file3');
	ok(!File::is->smallest($fn1, $fn3, $fn2), 'file1 is not the smallest of the three');
	
	# test thesame
	eval {
		ok(File::is->thesame($fn1, $fn1), 'file1 it self is thesame');
	};
	if ($@) {
		# rethrow if it is not error about MSWin32
		die $@
			if ($@ !~ m/MSWin32/);
		SKIP: {
			skip 'File::is->thesame does not work on MSWin32', 4;
		}
	}
	else {
		SKIP: {
			skip 'link() failed - not working on this filesystem?', 3
				if not eval { link($fn1,$fn1.'_'); 1; };
			skip 'symlink() failed - not working on this filesystem?', 3
				if not eval { symlink($fn1,$fn1.'__'); 1; };
			ok(File::is->thesame($fn1, $fn1.'_'), 'file1 is the same as file1_');
			ok(File::is->thesame($fn1, $fn1.'__'), 'file1 is the same as file1_');
			ok(!File::is->thesame($fn1, $fn2), 'file1 is not the same as file2');
		}
	}
	
	return 0;
}

