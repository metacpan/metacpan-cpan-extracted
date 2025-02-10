#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $EPUB = File::Spec->catfile(qw/t data gpl3.epub/);

my $ebook = EBook::Ishmael::EBook->new($EPUB);
isa_ok($ebook, 'EBook::Ishmael::EBook::Epub');

like($ebook->{Source}, qr/\Q$EPUB\E$/, "source ok");
like($ebook->{_container}, qr/container\.xml$/, "container ok");
like($ebook->{_rootfile}, qr/content\.opf$/, "rootfile ok");
is($ebook->{_contdir}, $ebook->{_unzip}, "content directory ok");

subtest "spine ok" => sub {

	plan tests => 5;

	like($ebook->{_spine}->[0], qr/titlepage\.xhtml$/, "spine[0] ok");
	like($ebook->{_spine}->[1], qr/index_split_000\.html$/, "spine[1] ok");
	like($ebook->{_spine}->[2], qr/index_split_001\.html$/, "spine[2] ok");
	like($ebook->{_spine}->[3], qr/index_split_002\.html$/, "spine[3] ok");

	is(@{ $ebook->{_spine} }, 4, "spine count ok");

};

is_deeply(
	$ebook->{Metadata},
	{
		title => [ 'gpl3' ],
		language => [ 'en' ],
		creator => [ 'Unknown' ],
		identifier => [ 'e3f35c22-0889-4539-9f97-eebf0d391b18', 'e3f35c22-0889-4539-9f97-eebf0d391b18' ],
		contributor => [ 'calibre (7.16.0) [https://calibre-ebook.com]' ],
		date => [ '0101-01-01T00:00:00+00:00' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

done_testing();
