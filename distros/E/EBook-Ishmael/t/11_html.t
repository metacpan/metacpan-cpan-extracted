#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $HTML = File::Spec->catfile(qw/t data gpl3.html/);

my $ebook = EBook::Ishmael::EBook->new($HTML);
isa_ok($ebook, 'EBook::Ishmael::EBook::HTML');

like($ebook->{Source}, qr/\Q$HTML\E$/, "source ok");

is_deeply(
	$ebook->metadata,
	{
		Language => [ 'en' ],
		Title => [ 'GNU General Public License v3.0 - GNU Project - Free Software Foundation (FSF)' ],
		Format => [ 'HTML' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

done_testing();
