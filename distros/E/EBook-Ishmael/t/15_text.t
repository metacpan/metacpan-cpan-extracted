#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $TXT = File::Spec->catfile(qw/t data gpl3.txt/);

my $ebook = EBook::Ishmael::EBook->new($TXT);
isa_ok($ebook, 'EBook::Ishmael::EBook::Text');

like($ebook->{Source}, qr/\Q$TXT\E$/, "source ok");

is($ebook->metadata->{Format}[0], 'Text', 'metadata format ok');
is($ebook->metadata->{Title}[0],  'gpl3.txt', 'metadata title ok');

# Modification time will probably differ, just check to make sure it exists.
ok($ebook->metadata->{Modified}[0], 'metadata modified ok');

ok($ebook->html, "html ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

done_testing();
