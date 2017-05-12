# vim: set ft=perl :

use strict;
use warnings;

require 't/helper.pl';
use Test::More tests => 1;

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my $got = split_paragraphs_to_text(slurp('t/corpus/multi-line.txt'),
    {
        add_attrs_to_p => { class => 'generated' },
    },
);
my $expected = slurp('t/corpus/multi-line_add-attrs-to-p.html');

is(remove_ignorable_whitespace($got), remove_ignorable_whitespace($expected));
