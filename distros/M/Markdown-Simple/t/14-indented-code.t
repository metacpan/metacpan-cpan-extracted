use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Indented (4-space) code blocks. CommonMark §4.4.
md_like( "    print 1\n",
    qr|<pre><code>print 1\s*</code></pre>|, 'one-line indented code' );
md_like( "    line1\n    line2\n",
    qr|<pre><code>line1\nline2\s*</code></pre>|, 'multi-line indented code' );
md_like( "\tprint 1\n",
    qr|<pre><code>print 1\s*</code></pre>|, 'tab-indented code' );

done_testing;
