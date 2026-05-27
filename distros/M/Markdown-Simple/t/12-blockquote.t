use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Blockquotes. CommonMark §5.1.
md_like( "> hello",                 qr|<blockquote>.*hello.*</blockquote>|s, 'simple bq' );
md_like( "> line1\n> line2",        qr|<blockquote>.*line1.*line2.*</blockquote>|s, 'multi-line bq' );
md_like( "> outer\n>> inner",       qr|<blockquote>.*<blockquote>.*inner.*</blockquote>.*</blockquote>|s, 'nested bq' );
md_like( "> **bold** quote",        qr|<blockquote>.*<strong>bold</strong>.*</blockquote>|s, 'inline markup inside bq' );

done_testing;
