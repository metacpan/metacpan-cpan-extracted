use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Line breaks. CommonMark §6.7 / §6.8.
md_unlike( "line1\nline2", qr|<br|, 'plain newline is not a hard break' );

md_like( "line1\nline2", qr|line1\s+line2|,
    'soft break preserves at least one space between lines' );

md_like( "line1  \nline2", qr|line1<br\s*/?>\s*line2|,
    'two-space hard break renders <br>' );

md_like( "line1\\\nline2", qr|line1<br\s*/?>\s*line2|,
    'trailing backslash hard break renders <br>' );

done_testing;
