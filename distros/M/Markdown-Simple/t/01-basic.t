use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Headers + a (broken — no separator row) "table" become a paragraph.
{
    my $md = "# header 1\n## header 2\n### header 3\n\n|table|heading|\n|one|two|\n|three|four|\n";
    my $html = markdown_to_html($md);
    like $html, qr|<h1>header 1</h1>|, 'h1';
    like $html, qr|<h2>header 2</h2>|, 'h2';
    like $html, qr|<h3>header 3</h3>|, 'h3';
    # No separator row => not a table; falls back to paragraph text.
    unlike $html, qr|<table>|, 'no <table> without separator row';
}

# A real GFM table.
{
    my $md = "| a | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |\n";
    my $html = markdown_to_html($md);
    like $html, qr|<table>|,            'table tag';
    like $html, qr|<th>a</th>|,         'header cell';
    like $html, qr|<td>3</td>|,         'body cell';
}

# Ordered list.
{
    my $html = markdown_to_html("1. one\n2. two\n3. three\n");
    like $html, qr|<ol>|,        'ordered list opens';
    like $html, qr|<li>one</li>|,'first item';
    like $html, qr|<li>three</li>|, 'last item';
}

# Unordered list.
{
    my $html = markdown_to_html("- one\n- two\n- three\n");
    like $html, qr|<ul>|,         'unordered list opens';
    like $html, qr|<li>two</li>|, 'middle item';
}

done_testing;
