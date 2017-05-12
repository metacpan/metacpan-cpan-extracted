use strict;
use warnings;
use Test::More 0.96;
use Test::Warnings;

use_ok('HTML::FormatMarkdown');

# Two tests of iasues raised in RT#111783
# These both failed in 2.14, and relate to Markdown handling of fragments.

is( HTML::FormatMarkdown->format_string('<a href="foo">foo</a>'), "[foo](foo)\n", 'Check for string emitted' );
is( HTML::FormatMarkdown->format_string('<img src="foo.jpg">foo</img>'),
    "![](foo.jpg)foo\n", 'Check for alt tag warning' );

# finish up
done_testing();
