#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::ImageID qw(image_id);

my $ZIP = File::Spec->catfile(qw/t data gpl3.zip/);

my $ebook = EBook::Ishmael::EBook->new($ZIP, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::Zip');

like($ebook->{Source}, qr/\Q$ZIP\E$/, "source ok");

is_deeply(
    $ebook->metadata->hash,
    {
        Title => 'gpl3',
        Format => 'Zip',
        Modified => (stat($ebook->{Source}))[9],
    },
    "metadata ok"
);

ok($ebook->html, "html ok");

subtest 'cover ok' => sub {
    ok($ebook->has_cover, "has cover");
    my ($img, $format) = $ebook->cover;
    is($format, 'png', 'cover is png');
    is(image_id($img), 'png', 'cover looks like png');
};

subtest 'images ok' => sub {
    is($ebook->image_num, 1, 'image count ok');
    my ($img, $format) = $ebook->image(0);
    is($format, 'png', "image #0 is png");
    is(image_id($img), 'png', "image #0 looks like png");
};

done_testing();
