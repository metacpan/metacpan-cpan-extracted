use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("```\ntest\n```\n"), "<pre><code>test\n</code></pre>\n", 'closed_fence_default');
is(convert("```\ntest\n"), "<p>```\ntest</p>\n", 'open_fence_default');
is(convert("```\ntest\n```\n", fenced_code_blocks_must_be_closed => 0), "<pre><code>test\n</code></pre>\n", 'closed_fence_false');
is(convert("```\ntest\n", fenced_code_blocks_must_be_closed => 0), "<pre><code>test\n</code></pre>\n", 'open_fence_false');
is(convert("```\ntest\n```\n", fenced_code_blocks_must_be_closed => 1), "<pre><code>test\n</code></pre>\n", 'closed_fence_true');
is(convert("```\ntest\n", fenced_code_blocks_must_be_closed => 1), "<p>```\ntest</p>\n", 'open_fence_true');
is(convert("~~~~\ntest\n~~~", fenced_code_blocks_must_be_closed => 0), "<pre><code>test\n~~~</code></pre>\n", 'smaller_fence');

is(convert(">```\n>test\n\nabc"), "<blockquote>\n<p>```\ntest</p>\n</blockquote>\n<p>abc</p>\n", 'in_blockquote_default');
is(convert(">```\n>test\n\nabc", fenced_code_blocks_must_be_closed => 0), "<blockquote>\n<pre><code>test\n</code></pre>\n</blockquote>\n<p>abc</p>\n", 'in_blockquote_open');

done_testing;
