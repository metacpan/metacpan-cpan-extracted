#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use EBook::Gutenberg::Get;

# Only tests gutenberg_link, does not test gutenberg_get as that requires remote
# fetching.

my $TEST_ID = 1;

my %FORMAT_TESTS = (
    'html'          => 'https://www.gutenberg.org/ebooks/1.html.images',
    'epub3'         => 'https://www.gutenberg.org/ebooks/1.epub3.images',
    'epub'          => 'https://www.gutenberg.org/ebooks/1.epub.images',
    'epub-noimages' => 'https://www.gutenberg.org/ebooks/1.epub.noimages',
    'kindle'        => 'https://www.gutenberg.org/ebooks/1.kf8.images',
    'mobi'          => 'https://www.gutenberg.org/ebooks/1.kindle.images',
    'text'          => 'https://www.gutenberg.org/ebooks/1.txt.utf-8',
    'zip'           => 'https://www.gutenberg.org/cache/epub/1/pg1-h.zip',
);

for my $fmt (sort keys %FORMAT_TESTS) {
    is(gutenberg_link($TEST_ID, $fmt), $FORMAT_TESTS{ $fmt }, "$fmt link ok");
}

done_testing;

# vim: expandtab shiftwidth=4
