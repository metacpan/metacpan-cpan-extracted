#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::ImageID qw(image_id);

my $FB = File::Spec->catfile(qw/t data gpl3.fb2/);

my $ebook = EBook::Ishmael::EBook->new($FB, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::FictionBook2');

like($ebook->{Source}, qr/\Q$FB\E$/, "source ok");

is_deeply(
    $ebook->metadata->hash,
    {
        Contributor => [ 'Unknown' ],
        Author => [ 'Unknown' ],
        Created => 1740441600,
        Genre => [ 'antique' ],
        ID => 'e3f35c22-0889-4539-9f97-eebf0d391b18',
        Language => [ 'en' ],
        Title => 'gpl3',
        Software => 'calibre 7.16.0',
        Format => 'FictionBook2 1.0',
    },
    "metadata ok"
);

ok($ebook->html, "html ok");

subtest 'cover ok' => sub {
    ok($ebook->has_cover, "has cover");
    my ($cover, $format) = $ebook->cover;
    is($format, 'jpg', 'cover is jpeg');
    is(image_id($cover), 'jpg', 'cover looks like jpeg');
};

subtest 'images ok' => sub {
    is($ebook->image_num, 1, 'image count ok');
    my ($img, $format) = $ebook->image(0);
    is($format, 'jpg', 'image #0 is jpeg');
    is(image_id($img), 'jpg', 'image #0 looks like jpeg');
};

done_testing();
