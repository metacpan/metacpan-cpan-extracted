use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

use Markdown::Simple qw/strip_markdown/;

# These actually work in the current implementation — gcov was just stale
# before the tests existed. Pin them down so they don't regress.
is( strip_markdown('see [click here](http://x) now'),
    'see click here now', 'link reduced to its visible text' );

is( strip_markdown('start ![a](x.png) end'),
    'start  end', 'image removed (leaves empty span)' );

is( strip_markdown('use `print` to output'),
    'use print to output', 'inline backticks removed' );

is( strip_markdown("before\n```\nhello\n```\nafter"),
    "before\n\nhello\n\nafter", 'fenced code fences removed' );

is( strip_markdown("- [ ] todo one\n- [x] done two"),
    "- todo one\n- done two", 'checkboxes removed; bullet remains' );

is( strip_markdown("1. one\n2. two"),
    "1. one\n2. two", 'ordered list dot preserved' );

done_testing;
