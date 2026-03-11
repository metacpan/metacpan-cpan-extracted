#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;
use Time::Piece;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::PDF;
use EBook::Ishmael::ImageID qw(image_id);

my $TEST_PDF = $ENV{TEST_PDF} // $EBook::Ishmael::EBook::PDF::CAN_TEST;

unless ($TEST_PDF) {
    plan skip_all => "TEST_PDF set to 0 or PDF utils are not installed";
}

my $PDF = File::Spec->catfile(qw/t data gpl3.pdf/);

my $ebook = EBook::Ishmael::EBook->new($PDF, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::PDF');

like($ebook->{Source}, qr/\Q$PDF\E$/, "source ok");

is(($ebook->metadata->author)[0], 'Unknown', 'metadata author ok');
is($ebook->metadata->format, 'PDF 1.4', 'metadata format ok');

is_deeply(
    [ $ebook->metadata->contributor ],
    [ 'calibre 7.16.0', 'calibre 7.16.0' ],
    'metadata software ok'
);

is($ebook->metadata->title, 'gpl3', 'metadata title ok');

SKIP: {
    unless ($Time::Piece::VERSION ge '1.38') {
        skip "Time::Piece $Time::Piece::VERSION cannot parse timezones correctly", 2;
    }
    is($ebook->metadata->created, 1738964834, 'metadata creation date ok');
    is($ebook->metadata->modified, 1738964834, 'metadata modification date ok');
}

ok($ebook->html, "html ok");

subtest 'cover ok' => sub {
    ok($ebook->has_cover, 'has cover');
    my ($img, $format) = $ebook->cover;
    is($format, 'png', 'cover is png');
    is(image_id($img), 'png', 'cover looks like a png');
};

subtest 'images ok' => sub {
    is($ebook->image_num, 0, 'image count ok');
    my ($img, $format) = $ebook->image(0);
    is($img, undef, 'no images found');
    is($format, undef, 'no images found');
};

done_testing();
