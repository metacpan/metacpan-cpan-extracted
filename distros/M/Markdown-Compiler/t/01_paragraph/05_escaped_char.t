#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Escape \\", 
    '\\', [
    [ result_is => "<p>\\</p>\n\n" ],
]);

build_and_test( "Escape \`", 
    '\`', [
    [ result_is => "<p>`</p>\n\n" ],
]);

build_and_test( "Escape *", 
    '\*', [
    [ result_is => "<p>*</p>\n\n" ],
]);

build_and_test( "Escape _", 
    '\_', [
    [ result_is => "<p>_</p>\n\n" ],
]);

build_and_test( "Escape {", 
    '\{', [
    [ result_is => "<p>{</p>\n\n" ],
]);

build_and_test( "Escape }", 
    '\}', [
    [ result_is => "<p>}</p>\n\n" ],
]);

build_and_test( "Escape [", 
    '\[', [
    [ result_is => "<p>[</p>\n\n" ],
]);

build_and_test( "Escape ]", 
    '\]', [
    [ result_is => "<p>]</p>\n\n" ],
]);

build_and_test( "Escape (", 
    '\(', [
    [ result_is => "<p>(</p>\n\n" ],
]);

build_and_test( "Escape )", 
    '\)', [
    [ result_is => "<p>)</p>\n\n" ],
]);

build_and_test( "Escape #", 
    '\#', [
    [ result_is => "<p>#</p>\n\n" ],
]);

build_and_test( "Escape +", 
    '\+', [
    [ result_is => "<p>+</p>\n\n" ],
]);

build_and_test( "Escape -", 
    '\-', [
    [ result_is => "<p>-</p>\n\n" ],
]);

build_and_test( "Escape .", 
    '\.', [
    [ result_is => "<p>.</p>\n\n" ],
]);

build_and_test( "Escape !", 
    '\!', [
    [ result_is => "<p>!</p>\n\n" ],
]);

done_testing;
