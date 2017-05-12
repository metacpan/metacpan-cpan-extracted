# vim: set ft=perl :

use strict;
use warnings;

require 't/helper.pl';
use Test::More tests => 1;

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my $got = split_paragraphs_to_text(slurp('t/corpus/multi-line.txt'),
    {
        use_instead_of_p => 'div',
    },
);
my $expected = slurp('t/corpus/multi-line_div-instead.html');

is(remove_ignorable_whitespace($got), remove_ignorable_whitespace($expected));
