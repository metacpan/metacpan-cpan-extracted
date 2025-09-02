#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $HTML = File::Spec->catfile(qw/t data gpl3.xhtml/);

my $ebook = EBook::Ishmael::EBook->new($HTML, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::XHTML');

like($ebook->{Source}, qr/\Q$HTML\E$/, "source ok");

is_deeply(
    $ebook->metadata,
    {
        Language => [ 'en' ],
        Title => [ 'GNU General Public License v3.0 - GNU Project - Free Software Foundation (FSF)' ],
        Format => [ 'XHTML' ],
    },
    "metadata ok"
);

ok($ebook->html, "html ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

is($ebook->image_num, 0, "image count ok");

is($ebook->image(0), undef, "image #0 ok");

done_testing();
