use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Nested lists. CommonMark §5.2 (indentation tracking).
md_like(
    "- outer\n  - inner1\n  - inner2\n",
    qr|<ul>\s*<li>outer\s*<ul>\s*<li>inner1</li>\s*<li>inner2</li>\s*</ul>\s*</li>\s*</ul>|,
    'two-level nested unordered list' );

md_like(
    "1. one\n   1. one.one\n   2. one.two\n2. two\n",
    qr|<ol>\s*<li>one\s*<ol>\s*<li>one\.one</li>\s*<li>one\.two</li>\s*</ol>\s*</li>\s*<li>two</li>\s*</ol>|,
    'nested ordered list' );

md_like(
    "- one\n  1. sub-a\n  2. sub-b\n",
    qr|<ul>\s*<li>one\s*<ol>\s*<li>sub-a</li>\s*<li>sub-b</li>\s*</ol>\s*</li>\s*</ul>|,
    'mixed nesting (ul -> ol)' );

done_testing;
