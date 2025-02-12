#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $FB = File::Spec->catfile(qw/t data gpl3.fb2/);

my $ebook = EBook::Ishmael::EBook->new($FB);
isa_ok($ebook, 'EBook::Ishmael::EBook::FictionBook2');

like($ebook->{Source}, qr/\Q$FB\E$/, "source ok");

is_deeply(
	$ebook->metadata,
	{
		Contributor => [ 'Unknown' ],
		Author => [ 'Unknown' ],
		Created => [
			'8.2.2025',
			'0101',
		],
		Genre => [ 'antique' ],
		ID => [ 'e3f35c22-0889-4539-9f97-eebf0d391b18' ],
		Language => [ 'en' ],
		Title => [ 'gpl3' ],
		Software => [ 'calibre 7.16.0' ],
		Format => [ 'FictionBook2 1.0' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

done_testing();
