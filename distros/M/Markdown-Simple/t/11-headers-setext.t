use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Setext headers (=== / ---). CommonMark §4.3.
md_like( "Title\n=====",    qr|<h1>Title</h1>|, 'setext h1' );
md_like( "Title\n-----",    qr|<h2>Title</h2>|, 'setext h2' );
md_like( "Title\n=",        qr|<h1>Title</h1>|, 'single = also valid' );
md_like( "Multi\nLine\n===", qr|<h1>Multi\s*Line</h1>|s, 'multi-line setext' );

done_testing;
