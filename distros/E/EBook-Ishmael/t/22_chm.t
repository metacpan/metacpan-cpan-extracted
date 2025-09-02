#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;
use EBook::Ishmael::EBook::CHM;
use EBook::Ishmael::ImageID;

my $TEST_CHM = $ENV{TEST_CHM} // $EBook::Ishmael::EBook::CHM::CAN_TEST;

unless ($TEST_CHM) {
    plan skip_all => "TEST_CHM set to 0 or chmlib not installed";
}

# I couldn't be bothered to figure out how to use Microsoft's CHM creator, so
# I just took a random CHM I found on the web (licensed under the GPL3).
my $CHM = File::Spec->catfile(qw/t data web2help.chm/);

my $ebook = EBook::Ishmael::EBook->new($CHM, undef, undef, 0);
isa_ok($ebook, 'EBook::Ishmael::EBook::CHM');

like($ebook->{Source}, qr/\Q$CHM\E$/, "source ok");

is($ebook->metadata->{Format}[0], 'CHM', 'metadata format ok');
is($ebook->metadata->{Title}[0],  'web2help', 'metadata title ok');

# Modification time will probably differ, just check to make sure it exists.
ok($ebook->metadata->{Modified}[0], 'metadata modified ok');

ok($ebook->html, "html ok");
ok($ebook->raw,  "raw ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

is($ebook->image_num, 2, "image count ok");

is(
    image_id($ebook->image(0)),
    "gif",
    "image #0 ok"
);

is(
    image_id($ebook->image(1)),
    "gif",
    "image #1 ok"
);

done_testing();
