use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Plain text with HTML metacharacters is escaped.
like markdown_to_html("a & b\n"),       qr|a &amp; b|,                  '& -> &amp;';
like markdown_to_html("a < b > c\n"),   qr|a &lt; b &gt; c|,            '< and > escaped';

# <script> in a paragraph is escaped (disallow_raw_html default).
{
    my $h = markdown_to_html("<script>alert(1)</script>\n");
    unlike $h, qr|<script>|, 'script tag not passed through';
}

# Dangerous URL schemes get neutralised in link href / image src.
unlike markdown_to_html("[click](javascript:alert(1))\n"),
    qr|href="javascript:|i, 'javascript: URL stripped';
unlike markdown_to_html("[click](vbscript:alert(1))\n"),
    qr|href="vbscript:|i,   'vbscript: URL stripped';
unlike markdown_to_html("[click](data:text/html,<script>alert(1)</script>)\n"),
    qr|href="data:text/html|i, 'data:text/html URL stripped';

done_testing;
