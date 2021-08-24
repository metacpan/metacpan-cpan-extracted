#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Italic word with underline.", 
    "Hello _world_.", [
    [ result_is => "<p>Hello <em>world</em>.</p>\n\n" ],
]);

build_and_test( "Italic phrase with underline.", 
    "_Hello world_.", [
    [ result_is => "<p><em>Hello world</em>.</p>\n\n" ],
]);

build_and_test( "Italic word with asterix.", 
    "Hello *world*.", [
    [ result_is => "<p>Hello <em>world</em>.</p>\n\n" ],
]);

build_and_test( "Italic phrase with asterix.",
    "*Hello world*.", [
    [ result_is => "<p><em>Hello world</em>.</p>\n\n" ],
]);

build_and_test( "Normal multiplication when space proceeds.",
    "5 * 3 * 4", [
    [ result_is => "<p>5 * 3 * 4</p>\n\n" ],
]);

build_and_test( "Normal multiplication when space proceeds.", 
    "5 * 3", [
    [ result_is => "<p>5 * 3</p>\n\n" ],
]);

build_and_test( "Italic works with space after closing.",
    "*Hello* World", [
    [ result_is => "<p><em>Hello</em> World</p>\n\n" ],
]);

build_and_test( "Italic works with space before opening.",
    "Hello *World*", [
    [ result_is => "<p>Hello <em>World</em></p>\n\n" ],
]);

done_testing;
