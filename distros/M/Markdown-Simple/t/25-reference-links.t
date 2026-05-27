use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

md_like( "See [foo][1].\n\n[1]: http://example.com",
    qr|<a href="http://example\.com">foo</a>|,
    'full reference link [foo][1]' );

md_like( "See [foo][].\n\n[foo]: http://example.com",
    qr|<a href="http://example\.com">foo</a>|,
    'collapsed reference link [foo][]' );

md_like( "See [foo].\n\n[foo]: http://example.com",
    qr|<a href="http://example\.com">foo</a>|,
    'shortcut reference link [foo]' );

md_like( "![alt][img]\n\n[img]: pic.png \"t\"",
    qr{<img\b(?:[^>]*\balt="alt"[^>]*\bsrc="pic\.png"|[^>]*\bsrc="pic\.png"[^>]*\balt="alt")[^>]*\btitle="t"}s,
    'reference image with title (any attr order)' );

# The literal definition line must not leak into the rendered output.
md_unlike( "See [foo][1].\n\n[1]: http://example.com",
    qr|\[1\]:\s*http|,
    'link definition line consumed (not echoed verbatim)' );

done_testing;
