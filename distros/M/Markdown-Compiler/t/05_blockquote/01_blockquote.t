#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "General Blockquotes work.", "> Hi.\n> Hi.\n", [
    [ result_is => "<blockquote>Hi.\nHi.</blockquote>\n\n" ],
]);

done_testing;
