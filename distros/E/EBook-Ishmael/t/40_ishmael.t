#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use File::Which;

use EBook::Ishmael;
use EBook::Ishmael::TextBrowserDump;

my @FILES = map { File::Spec->catfile(qw(t data), $_) } qw(
	gpl3.epub gpl3.fb2 gpl3.html gpl3.mobi gpl3.pdb gpl3.txt gpl3.xhtml
	gpl3.ztxt
);

# Only test PDF if required utilities are installed.
if (defined which('pdftohtml') and defined which('pdfinfo')) {
	push @FILES, File::Spec->catfile(qw(t data gpl3.pdf));
}

for my $f (@FILES) {

	my $ishmael;

	my $file = $f =~ /\.(.+)$/;

	@ARGV = ('-H', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-H w/ $file ok");

	@ARGV = ('-i', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-i w/ $file ok");

	@ARGV = ('-j', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-j w/ $file ok");

	@ARGV = ('-m', $f);
	$ishmael = EBook::Ishmael->init();

	ok($ishmael->run, "-m w/ $file ok");

	SKIP: {

		unless ($EBook::Ishmael::TextBrowserDump::CAN_DUMP) {
			skip 'no valid text browser installed', 1;
		}

		@ARGV = ($f);
		$ishmael = EBook::Ishmael->init();

		ok($ishmael->run, "text dump w/ $file ok");

	}

}

done_testing();
