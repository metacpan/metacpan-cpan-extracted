#!/usr/bin/perl

use lib 't/lib';
use KwikiMarkdownTest;

plan tests => 1 * blocks;

run_is input => 'expected';

__END__
=== Test one
--- input markdown_filter
This is only a test
containing two lines.
--- expected
<p>This is only a test
containing two lines.</p>

