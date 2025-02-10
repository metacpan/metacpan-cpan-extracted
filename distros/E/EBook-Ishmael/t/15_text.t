#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $TXT = File::Spec->catfile(qw/t data gpl3.txt/);

my $ebook = EBook::Ishmael::EBook->new($TXT);
isa_ok($ebook, 'EBook::Ishmael::EBook::Text');

like($ebook->{Source}, qr/\Q$TXT\E$/, "source ok");

is_deeply(
	$ebook->metadata,
	{
		title => [ 'gpl3.txt' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

done_testing();
