use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# All six ATX levels work today.
md_like( "# h1",      qr|<h1>h1</h1>|, 'h1 renders' );
md_like( "## h2",     qr|<h2>h2</h2>|, 'h2 renders' );
md_like( "### h3",    qr|<h3>h3</h3>|, 'h3 renders' );
md_like( "#### h4",   qr|<h4>h4</h4>|, 'h4 renders' );
md_like( "##### h5",  qr|<h5>h5</h5>|, 'h5 renders' );
md_like( "###### h6", qr|<h6>h6</h6>|, 'h6 renders' );

# # without trailing space is correctly NOT a header.
md_unlike( "#h", qr|<h1|, '"#h" (no space) is not a header' );

md_unlike( "####### x", qr|<h7|, 'seven hashes should not be h7' );
md_like(   "# h #",     qr|<h1>h</h1>|, 'trailing # stripped' );
md_like(   "  # h",     qr|<h1>h</h1>|, 'up to 3 leading spaces consumed cleanly' );
md_unlike( "    # h",   qr|<h1|, '4-space indent = code block, not h1' );

done_testing;
