# vim: set ft=perl :

use strict;
use warnings;

require 't/helper.pl';
use Test::More tests => 1;

use HTML::ParagraphSplit qw( split_paragraphs_to_text );

my $id = 0;
my $got = split_paragraphs_to_text(slurp('t/corpus/multi-line.txt'),
    {
        filter_added_nodes => 
            sub { 
                my $element = shift;
                $element->id('blah-'.$id);
                $id++;
            },
    },
);
my $expected = slurp('t/corpus/multi-line_filter-nodes.html');

is(remove_ignorable_whitespace($got), remove_ignorable_whitespace($expected));
