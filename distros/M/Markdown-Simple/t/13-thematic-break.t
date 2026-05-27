use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

md_like( "---",         qr|<hr\s*/?>|, 'dash hr' );
md_like( "***",         qr|<hr\s*/?>|, 'asterisk hr' );
md_like( "___",         qr|<hr\s*/?>|, 'underscore hr' );
md_like( "- - -",       qr|<hr\s*/?>|, 'spaced dashes hr' );
md_like( "----------",  qr|<hr\s*/?>|, 'long hr' );

done_testing;
