#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::CBR;
use EBook::Ishmael::ImageID qw(image_id);

my $TEST_CBR = $ENV{TEST_CBR} // $EBook::Ishmael::EBook::CBR::CAN_TEST;

unless ($TEST_CBR) {
    plan skip_all => "TEST_CBR set to 0 or unrar not installed";
}

my $CBR = File::Spec->catfile(qw/t data gpl3.cbr/);

my $ebook = EBook::Ishmael::EBook->new($CBR);
isa_ok($ebook, 'EBook::Ishmael::EBook::CBR');

like($ebook->{Source}, qr/\Q$CBR\E$/, "source ok");

is($ebook->metadata->format, 'CBR', 'metadata format ok');
is($ebook->metadata->title,  'gpl3', 'metadata title ok');

# Modification time will probably differ, just check to make sure it exists.
ok($ebook->metadata->modified, 'metadata modified ok');

ok(!$ebook->html, "html ok");
ok(!$ebook->raw,  "raw ok");

subtest 'cover ok' => sub {
    ok($ebook->has_cover, "has cover");
    my ($img, $format) = $ebook->cover;
    is($format, 'png', 'cover is png');
    is(image_id($img), 'png', 'cover looks like png');
};

subtest 'images ok' => sub {
    is($ebook->image_num, 28, 'image count ok');
    for my $i (0 .. 27) {
        my ($img, $format) = $ebook->image($i);
        is($format, 'png', "image #$i is png");
        is(image_id($img), 'png', "image #$i looks like png");
    }
};

done_testing();
