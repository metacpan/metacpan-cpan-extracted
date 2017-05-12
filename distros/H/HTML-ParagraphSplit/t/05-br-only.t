# vim: set ft=perl :

use strict;
use warnings;

require 't/helper.pl';
use Test::More tests => 7;

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my @filenames = qw(
    one-line
    multi-line
    use-br
    with-barrier-blocks
    with-explicit-blocks
    with-extra-breaks
    with-phrases
);

for my $filename (@filenames) {
    my $got = split_paragraphs_to_text(slurp("t/corpus/$filename.txt"),
        {
           use_br_instead_of_p => 1,
        },
    ); 
    my $expected = slurp("t/corpus/${filename}_br-only.html");

    is(remove_ignorable_whitespace($got), 
        remove_ignorable_whitespace($expected));
}

