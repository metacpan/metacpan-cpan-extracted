#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Path qw(remove_tree);
use File::Spec;
use File::Temp qw(tempdir tempfile);

use EBook::Ishmael;
# For CAN_TEST
use EBook::Ishmael::EBook::CB7;
use EBook::Ishmael::EBook::CBR;
use EBook::Ishmael::EBook::CHM;
use EBook::Ishmael::EBook::PDF;
use EBook::Ishmael::TextBrowserDump;

my $TEST_PDF = $ENV{TEST_PDF} // $EBook::Ishmael::EBook::PDF::CAN_TEST;

my @FILES = map { File::Spec->catfile(qw(t data), $_) } qw(
	gpl3.epub gpl3.fb2 gpl3.html gpl3.mobi gpl3.pdb gpl3.txt gpl3.xhtml
	gpl3.ztxt gpl3.pdf gpl3.cbr  gpl3.cbz  gpl3.cb7 web2help.chm
);

my %IMAGES = (
	epub  => 1,
	fb2   => 1,
	html  => 0,
	mobi  => 2,
	pdb   => 0,
	txt   => 0,
	xhtml => 0,
	ztxt  => 0,
	pdf   => 0,
	cbr   => 28,
	cbz   => 28,
	cb7   => 28,
	chm   => 2,
);

my $tmpimg = do {
	my ($fh, $tmp) = tempfile(UNLINK => 1);
	close $fh;
	$tmp;
};

for my $f (@FILES) { SKIP: {

	my $ishmael;

	my ($file) = $f =~ /\.(.+)$/;

	if (!$TEST_PDF and $file eq 'pdf') {
		skip "TEST_PDF set to 0 or poppler utils not installed", 8;
	}

	if (!$EBook::Ishmael::EBook::CBR::CAN_TEST and $file eq 'cbr') {
		skip "unrar not installed", 8;
	}

	if (!$EBook::Ishmael::EBook::CB7::CAN_TEST and $file eq 'cb7') {
		skip "7z not installed", 8;
	}

	if (!$EBook::ishmael::EBook::CHM::CAN_TEST and $file eq 'chm') {
		skip "chmlib not installed", 8;
	}

	@ARGV = ('-H', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-H w/ $file ok");

	@ARGV = ('-i', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-i w/ $file ok");

	@ARGV = (qw(-m ishmael), $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m ishmael w/ $file ok");

	@ARGV = (qw(-m json), $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m json w/ $file ok");

	@ARGV = (qw(-m pjson), $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m pjson w/ $file ok");

	@ARGV = (qw(-m xml), $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m xml w/ $file ok");

	@ARGV = (qw(-m pxml), $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m pxml w/ $file ok");

	@ARGV = ('-r', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-r w/ $file ok");

	@ARGV = ('-c', $f, $tmpimg);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-c w/ $file ok");

	my $tmp = tempdir(CLEANUP => 1);

	@ARGV = ('-g', $f, $tmp);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-g w/ $file ok");

	my @glob = glob "$tmp/*";

	is(
		scalar @glob,
		$IMAGES{ $file },
		"-g dump count w/ $file ok"
	);

	remove_tree($tmp, { safe => 1 });

}}

done_testing();
