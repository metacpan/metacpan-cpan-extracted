#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::CB7;
use EBook::Ishmael::ImageID;

my $TEST_CB7 = $ENV{TEST_CB7} // $EBook::Ishmael::EBook::CB7::CAN_TEST;

unless ($TEST_CB7) {
	plan skip_all => "TEST_CB7 set to 0 or 7z not installed";
}

my $CB7 = File::Spec->catfile(qw/t data gpl3.cb7/);

my $ebook = EBook::Ishmael::EBook->new($CB7);
isa_ok($ebook, 'EBook::Ishmael::EBook::CB7');

like($ebook->{Source}, qr/\Q$CB7\E$/, "source ok");

is($ebook->metadata->{Format}[0], 'CB7', 'metadata format ok');
is($ebook->metadata->{Title}[0],  'gpl3', 'metadata title ok');

# Modification time will probably differ, just check to make sure it exists.
ok($ebook->metadata->{Modified}[0], 'metadata modified ok');

ok(!$ebook->html, "html ok");
ok(!$ebook->raw,  "raw ok");

ok($ebook->has_cover, "has cover");

ok($ebook->cover, "cover ok");
is(
	image_id(\($ebook->cover)),
	"png",
	"cover looks like a png"
);

is($ebook->image_num, 28, "image count ok");

for my $i (0 .. 27) {
	is(
		image_id($ebook->image($i)),
		"png",
		"image #$i ok"
	);
}

done_testing();
