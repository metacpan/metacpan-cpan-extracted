# vim: set ft=perl :

use strict;
use warnings;

require 't/helper.pl';
use Test::More tests => 2;

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my $got = split_paragraphs_to_text(
    slurp('t/corpus/use-br.txt'), {
        single_line_breaks_to_br => 1,
    },
);
my $expected = slurp('t/corpus/use-br.html');

is(remove_ignorable_whitespace($got), remove_ignorable_whitespace($expected));

$got = split_paragraphs_to_text(
    slurp('t/corpus/if-can-tighten.txt'), {
        single_line_breaks_to_br => 1,
        br_only_if_can_tighten   => 1,
    },
);
$expected = slurp('t/corpus/if-can-tighten.html');

is(remove_ignorable_whitespace($got), remove_ignorable_whitespace($expected));
