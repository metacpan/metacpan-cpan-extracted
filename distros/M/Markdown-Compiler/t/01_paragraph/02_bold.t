#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Bold word with underline.", 
    "Hello __world__.", [
    [ result_is => "<p>Hello <strong>world</strong>.</p>\n\n" ],
]);

build_and_test( "Bold phrase with underline.", 
    "__Hello world__.", [
    [ result_is => "<p><strong>Hello world</strong>.</p>\n\n" ],
]);

build_and_test( "Bold word with asterix.", 
    "Hello **world**.", [
    [ result_is => "<p>Hello <strong>world</strong>.</p>\n\n" ],
]);

build_and_test( "Bold phrase with asterix.",
    "**Hello world**.", [
    [ result_is => "<p><strong>Hello world</strong>.</p>\n\n" ],
]);

build_and_test( "Normal multiplication when space proceeds.",
    "5 * 3 * 4", [
    [ result_is => "<p>5 * 3 * 4</p>\n\n" ],
]);

build_and_test( "Normal multiplication when space proceeds.", 
    "5 * 3", [
    [ result_is => "<p>5 * 3</p>\n\n" ],
]);

build_and_test( "Bold works with space after closing.",
    "**Hello** World", [
    [ result_is => "<p><strong>Hello</strong> World</p>\n\n" ],
]);

build_and_test( "Bold works with space before opening.",
    "Hello **World**", [
    [ result_is => "<p>Hello <strong>World</strong></p>\n\n" ],
]);

done_testing;
