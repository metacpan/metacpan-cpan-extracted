#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use File::Which;

use EBook::Ishmael::EBook;

unless (
	defined which 'pdftohtml' and
	defined which 'pdfinfo'
) {
	plan skip_all => "Poppler utils are not installed";
}

my $PDF = File::Spec->catfile(qw/t data gpl3.pdf/);

my $ebook = EBook::Ishmael::EBook->new($PDF);
isa_ok($ebook, 'EBook::Ishmael::EBook::PDF');

like($ebook->{Source}, qr/\Q$PDF\E$/, "source ok");

is_deeply(
	$ebook->metadata,
	{
		'author' => [ 'Unknown' ],
		'creationdate' => [ 'Fri Feb  7 15:47:14 2025 CST' ],
		'creator' => [ 'calibre 7.16.0' ],
		'custom metadata' => [ 'no' ],
		'encrypted' => [ 'no' ],
		'file size' => [ '85226 bytes' ],
		'form' => [ 'none' ],
		'javascript' => [ 'no' ],
		'metadata stream' => [ 'yes' ],
		'moddate' => [ 'Fri Feb  7 15:47:14 2025 CST' ],
		'optimized' => [ 'no' ],
		'page rot' => [ '0' ],
		'page size' => [ '612 x 792 pts (letter)' ],
		'pages' => [ '28' ],
		'pdf version' => [ '1.4' ],
		'producer' => [ 'calibre 7.16.0' ],
		'suspects' => [ 'no' ],
		'tagged' => [ 'no' ],
		'title' => [ 'gpl3' ],
		'userproperties' => [ 'no' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

done_testing();
