#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::ImageID;

my $ZIP = File::Spec->catfile(qw/t data gpl3.zip/);

my $ebook = EBook::Ishmael::EBook->new($ZIP, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::Zip');

like($ebook->{Source}, qr/\Q$ZIP\E$/, "source ok");

is_deeply(
	$ebook->metadata,
	{
		Title => [ 'gpl3' ],
		Format => [ 'Zip' ],
		Modified => [ scalar gmtime((stat($ebook->{Source}))[9]) ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

ok($ebook->has_cover, "has cover");

is(
	image_id(\($ebook->cover)),
	'png',
	"cover looks like a png"
);

is($ebook->image_num, 1, "image count ok");

is(
	image_id($ebook->image(0)),
	"png",
	"image #0 ok"
);

done_testing();
