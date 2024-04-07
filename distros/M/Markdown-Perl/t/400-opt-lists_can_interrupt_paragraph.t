use strict;
use warnings;
use utf8;

use FindBin;
use lib "${FindBin::Bin}/lib";

use HtmlSanitizer;
use Markdown::Perl 'convert';
use Test2::V0;

my @tests = (
  ["- foo\n- bar", 'ul',
    "<ul><li>foo</li><li>bar</li></ul>",
    "<ul><li>foo</li><li>bar</li></ul>",
    "<ul><li>foo</li><li>bar</li></ul>",
    "<ul><li>foo</li><li>bar</li></ul>"],
  ["foo\n- bar", 'ul_after_paragraph',
    "<p>foo\n- bar</p>",
    "<p>foo\n- bar</p>",
    "<p>foo</p><ul><li>bar</li></ul>",
    "<p>foo</p><ul><li>bar</li></ul>"],
  ["foo\n1. bar", 'ol1_after_paragraph',
    "<p>foo\n1. bar</p>",
    "<p>foo\n1. bar</p>",
    "<p>foo</p><ol><li>bar</li></ol>",
    "<p>foo</p><ol><li>bar</li></ol>"],
  ["foo\n8. bar", 'ol8_after_paragraph',
    "<p>foo\n8. bar</p>",
    "<p>foo\n8. bar</p>",
    "<p>foo\n8. bar</p>",
    "<p>foo</p><ol start=\"8\"><li>bar</li></ol>"],
  ["- foo\n  - bar", 'ulul',
    "<ul><li>foo\n- bar</li></ul>",
    "<ul><li>foo<ul><li>bar</li></ul></li></ul>",
    "<ul><li>foo<ul><li>bar</li></ul></li></ul>",
    "<ul><li>foo<ul><li>bar</li></ul></li></ul>"],
  ["- foo\n  bar\n  - baz", 'ulpul',
    "<ul><li>foo\nbar\n- baz</li></ul>",
    "<ul><li>foo\nbar<ul><li>baz</li></ul></li></ul>",
    "<ul><li>foo\nbar<ul><li>baz</li></ul></li></ul>",
    "<ul><li>foo\nbar<ul><li>baz</li></ul></li></ul>"],
  ["- foo\n  bar\n  8. baz", 'ulpol8',
    "<ul><li>foo\nbar\n8. baz</li></ul>",
    "<ul><li>foo\nbar<ol start=\"8\"><li>baz</li></ol></li></ul>",
    "<ul><li>foo\nbar\n8. baz</li></ul>",
    "<ul><li>foo\nbar<ol start=\"8\"><li>baz</li></ol></li></ul>"]
);

my @opt_val = qw(never within_list strict always);

my @tt = map { [ Markdown::Perl->new(lists_can_interrupt_paragraph => $_), $_ ] } @opt_val;

for my $t (@tests) {
  my ($html, $name, @tc) = @{$t};
  for my $i (0..3) {
    is(sanitize_html($tt[$i][0]->convert($html), 1), $tc[$i], $name.'_'.$tt[$i][1]);
  }
}

done_testing;
