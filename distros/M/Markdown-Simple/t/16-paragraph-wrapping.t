use strict;
use warnings;
use Test::More;
use Markdown::Simple;

like   markdown_to_html("hello\n"),               qr|<p>hello</p>|,             'paragraph -> <p>';
like   markdown_to_html("para1\n\npara2\n"),      qr|<p>para1</p>\s*<p>para2</p>|, 'blank line splits paragraphs';
like   markdown_to_html("line1\nline2\n"),        qr|<p>line1\nline2</p>|,      'soft break joins paragraph';
unlike markdown_to_html("hello\n"),               qr|<div>|,                    'no <div> wrapper';

done_testing;
