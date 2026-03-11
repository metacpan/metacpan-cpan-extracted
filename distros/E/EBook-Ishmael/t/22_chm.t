#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::CHM;
use EBook::Ishmael::ImageID qw(image_id);

my $TEST_CHM = $ENV{TEST_CHM} // $EBook::Ishmael::EBook::CHM::CAN_TEST;

unless ($TEST_CHM) {
    plan skip_all => "TEST_CHM set to 0 or extract_chmLib nor hh.exe installed";
}

# I couldn't be bothered to figure out how to use Microsoft's CHM creator, so
# I just took a random CHM I found on the web (licensed under the GPL3).
my $CHM = File::Spec->catfile(qw/t data web2help.chm/);

my $ebook = EBook::Ishmael::EBook->new($CHM, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::CHM');

like($ebook->{Source}, qr/\Q$CHM\E$/, "source ok");

is($ebook->metadata->format, 'CHM', 'metadata format ok');
is($ebook->metadata->title,  'web2help', 'metadata title ok');

# Modification time will probably differ, just check to make sure it exists.
ok($ebook->metadata->modified, 'metadata modified ok');

ok($ebook->html, "html ok");
ok($ebook->raw,  "raw ok");

subtest 'cover ok' => sub {
    TODO: {
        local $TODO = "can't determine whether cover exists prior to dumping";
        ok(!$ebook->has_cover, "has no cover");
    }
    my ($img, $format) = $ebook->cover;
    ok(! defined $img && ! defined $format, 'no cover found');
};

subtest 'images ok' => sub {
    is($ebook->image_num, 2, 'image count ok');
    for my $i (0, 1) {
        my ($img, $format) = $ebook->image($i);
        is($format, 'gif', "image #$i is gif");
        is(image_id($img), 'gif', "image #$i looks like gif");
    }
};

done_testing();
