use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Inline emphasis in a paragraph and inside lists & tables.

{
    my $html = markdown_to_html("**bold** *italic* ~~strike~~\n\n- one **bold**\n- two *italic*\n- three ~~strike~~\n");
    like $html, qr|<p><strong>bold</strong> <em>italic</em> <del>strike</del></p>|, 'inline emphasis paragraph';
    like $html, qr|<li>one <strong>bold</strong></li>|,    'bold inside list';
    like $html, qr|<li>two <em>italic</em></li>|,          'italic inside list';
    like $html, qr|<li>three <del>strike</del></li>|,      'strike inside list';
}

{
    my $html = markdown_to_html("**bold** *italic* ~~strike~~\n\n1. one **bold**\n2. two *italic*\n3. three ~~strike~~\n");
    like $html, qr|<ol>|,                              'ordered list opens';
    like $html, qr|<li>one <strong>bold</strong></li>|, 'ol: bold';
}

{
    my $md =
        "**bold** *italic* ~~strike~~\n\n"
      . "|table|one|two|\n"
      . "|-----|---|---|\n"
      . "|one **bold**|two *italic*|three ~~strike~~|\n";
    my $html = markdown_to_html($md);
    like $html, qr|<table>|,                              'table built';
    like $html, qr|<td>one <strong>bold</strong></td>|,   'bold in cell';
    like $html, qr|<td>two <em>italic</em></td>|,         'italic in cell';
    like $html, qr|<td>three <del>strike</del></td>|,     'strike in cell';
}

done_testing;
