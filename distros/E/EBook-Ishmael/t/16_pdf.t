#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use File::Which;

use EBook::Ishmael::EBook;

my $TEST_PDF =
	$ENV{TEST_PDF} //
	(which('pdftohtml') and which('pdfinfo') and which('pdftopng'));

unless ($TEST_PDF) {
	plan skip_all => "TEST_PDF set to 0, or poppler utils are not installed";
}

my $PDF = File::Spec->catfile(qw/t data gpl3.pdf/);

my $ebook = EBook::Ishmael::EBook->new($PDF);
isa_ok($ebook, 'EBook::Ishmael::EBook::PDF');

like($ebook->{Source}, qr/\Q$PDF\E$/, "source ok");

is($ebook->metadata->{Author}[0], 'Unknown', 'metadata author ok');
is($ebook->metadata->{Format}[0], 'PDF 1.4', 'metadata format ok');

is_deeply(
	$ebook->metadata->{Contributor},
	[ 'calibre 7.16.0', 'calibre 7.16.0' ],
	'metadata software ok'
);

is($ebook->metadata->{Title}[0], 'gpl3', 'metadata title ok');

# The dates can differ between pdfinfo versions, so just check to make sure
# they are present.
ok($ebook->metadata->{Created}[0], 'metadata creation date ok');
ok($ebook->metadata->{Modified}[0], 'metadata modification date ok');

ok($ebook->html, "html ok");

ok($ebook->has_cover, "has cover");

is(
	substr($ebook->cover, 0, 8),
	pack("CCCCCCCC", 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a),
	"cover looks like a png"
);

done_testing();
