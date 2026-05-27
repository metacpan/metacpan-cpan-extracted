use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Backslash escapes per CommonMark §6.1.
unlike markdown_to_html("\\*not italic\\*\n"), qr|<em>|,
    '\\* does not emphasise';
like   markdown_to_html("\\*not italic\\*\n"), qr|\Q*not italic*\E|,
    '\\* renders as literal asterisks';

unlike markdown_to_html("\\[not a link\\]\n"), qr|<a |,
    '\\[ ... \\] does not produce a link';
like   markdown_to_html("\\[not a link\\]\n"), qr|\Q[not a link]\E|,
    '\\[ ... \\] renders as literal brackets';

unlike markdown_to_html("\\`not code\\`\n"), qr|<code>|,
    '\\` does not open inline code';

done_testing;
