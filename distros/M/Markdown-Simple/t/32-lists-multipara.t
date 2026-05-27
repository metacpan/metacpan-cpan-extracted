use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Multi-paragraph / loose list items. CommonMark §5.3.
md_like(
    "- one\n\n  second para of one\n\n- two\n",
    qr|<li>\s*<p>one</p>\s*<p>second para of one</p>\s*</li>|s,
    'list item with two paragraphs' );

md_like(
    "- item\n\n      indented code\n",
    qr|<li>.*<pre><code>indented code\s*</code></pre>.*</li>|s,
    'list item containing indented code block' );

done_testing;
