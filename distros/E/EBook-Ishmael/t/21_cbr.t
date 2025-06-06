#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::CBR;
use EBook::Ishmael::ImageID;

my $TEST_CBR = $ENV{TEST_CBR} // $EBook::Ishmael::EBook::CBR::CAN_TEST;

unless ($TEST_CBR) {
	plan skip_all => "TEST_CBR set to 0 or unrar not installed";
}

my $CBR = File::Spec->catfile(qw/t data gpl3.cbr/);

my $ebook = EBook::Ishmael::EBook->new($CBR);
isa_ok($ebook, 'EBook::Ishmael::EBook::CBR');

like($ebook->{Source}, qr/\Q$CBR\E$/, "source ok");

is($ebook->metadata->{Format}[0], 'CBR', 'metadata format ok');
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
