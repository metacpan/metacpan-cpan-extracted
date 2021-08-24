#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Inline code in paragraphs works.",
    "This causes an error: `> hello`.", [
    [ result_is => "<p>This causes an error: <span class=\"inline-code\">> hello</span>.</p>\n\n" ],
]);

build_and_test( "InlineCode is valid paragraph starter",
    "`This` causes an error.", [
    [ result_is => "<p><span class=\"inline-code\">This</span> causes an error.</p>\n\n" ],
]);



done_testing;

