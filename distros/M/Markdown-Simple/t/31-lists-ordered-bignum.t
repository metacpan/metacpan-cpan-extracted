use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Document the BUG: ordered list digits 1..9 work, but 10+ silently drops out
# of list parsing. See lib/Markdown/Simple.xs:277 — `*p >= '1' && *p <= '9'`.

md_like( "1. one\n2. two", qr|<ol>.*<li>one</li>.*<li>two</li>.*</ol>|s,
    'single-digit ordered list (sanity)' );

md_like(
    "100. hundred",
    qr|<ol[^>]*>.*<li>hundred</li>.*</ol>|s,
    'triple-digit marker recognised' );

md_like(
    "9. nine\n10. ten\n11. eleven",
    qr|<ol[^>]*>.*<li>nine</li>.*<li>ten</li>.*<li>eleven</li>.*</ol>|s,
    'list spans single->double digit markers' );

md_like(
    "10. ten\n11. eleven",
    qr|<ol[^>]*>.*<li>ten</li>.*<li>eleven</li>.*</ol>|s,
    'list starts at double-digit marker' );

# CommonMark allows a custom `start` attribute on <ol>.
md_like(
    "5. five\n6. six",
    qr|<ol start="5">|,
    'ol carries start= attribute when not starting at 1' );

done_testing;
