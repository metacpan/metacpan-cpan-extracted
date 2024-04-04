use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("```\ntest\n```\n"), "<pre><code>test\n</code></pre>\n", 'parse_fenced_code_block');
is(convert("```\ntest\n```\n", use_fenced_code_blocks => 0), "<p><code>test</code></p>\n", 'does_not_parse_fenced_code_block');

done_testing;
