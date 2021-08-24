#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Zero works", "This 0 exists.",   [ [ result_is => "<p>This 0 exists.</p>\n\n"   ] ]);
build_and_test( "Zero works", "This 20 exists.",  [ [ result_is => "<p>This 20 exists.</p>\n\n"  ] ]);
build_and_test( "Zero works", "This 02 exists.",  [ [ result_is => "<p>This 02 exists.</p>\n\n"  ] ]);
build_and_test( "Zero works", "This 3.0 exists.", [ [ result_is => "<p>This 3.0 exists.</p>\n\n" ] ]);
build_and_test( "Zero works", "This 0.3 exists.", [ [ result_is => "<p>This 0.3 exists.</p>\n\n" ] ]);

done_testing;
