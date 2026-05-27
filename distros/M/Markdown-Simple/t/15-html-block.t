use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Raw HTML blocks pass through verbatim.
like markdown_to_html("<div class=\"x\">raw</div>\n"),
    qr|<div class="x">raw</div>|, 'raw HTML element preserved';
like markdown_to_html("<!-- comment -->\n"),
    qr|<!-- comment -->|, 'HTML comment preserved';

# Inline HTML inside a paragraph.
like markdown_to_html("foo <strong>bar</strong>\n"),
    qr|<p>foo <strong>bar</strong></p>|, 'inline HTML preserved';

# The default GFM mode disallows a small set of dangerous raw tags
# (script, style, iframe, ...). They are escaped, not passed through.
unlike markdown_to_html("<script>alert(1)</script>\n"),
    qr|<script>|, 'raw <script> escaped by default (disallow_raw_html)';

done_testing;
