#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::ImageID qw(image_id);

my $CBZ = File::Spec->catfile(qw/t data gpl3.cbz/);

my $ebook = EBook::Ishmael::EBook->new($CBZ);
isa_ok($ebook, 'EBook::Ishmael::EBook::CBZ');

like($ebook->{Source}, qr/\Q$CBZ\E$/, "source ok");

is($ebook->metadata->format, 'CBZ', 'metadata format ok');
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
        is(image_id($img), 'png', "image #$1 looks like png");
    }
};

done_testing();
