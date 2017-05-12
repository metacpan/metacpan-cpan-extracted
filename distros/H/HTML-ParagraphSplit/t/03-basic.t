# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 8;
require 't/helper.pl';

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my @filenames = qw(
    one-line
    multi-line
    with-barrier-blocks
    with-explicit-blocks
    with-extra-breaks
    with-phrases
    with-entities
    with-wrapped-entities
);

for my $filename (@filenames) {
    my $input = slurp("t/corpus/$filename.txt");
    my $text_got = split_paragraphs_to_text($input);
    my $text_expected = slurp("t/corpus/$filename.html");

    # Don't let whitespace break things, it's irrelevant to these tests
    remove_ignorable_whitespace($text_got);
    remove_ignorable_whitespace($text_expected);

    is($text_got, $text_expected);
}

