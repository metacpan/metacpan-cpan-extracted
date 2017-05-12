use 5.008001;
use utf8;
use strict;
use warnings;
use Test::More 0.96;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use LeftPad;

# from https://github.com/camwest/left-pad/blob/master/test.js as of 2016-04-23
is( leftpad( 'foo',    5 ), '  foo',  "foo, 5" );
is( leftpad( 'foobar', 6 ), 'foobar', "foobar, 6" );
is( leftpad( 1, 2, 0 ),   '01', "1,2,0" );
is( leftpad( 1, 2, '-' ), '-1', "1,2,-" );

# additional tests
is( leftpad( "foobar", 5 ), "foobar", "foobar, 5" );
is( leftpad( undef,    6 ), "      ", "<undef>,6" );
is( leftpad( undef, 6, "0" ), "000000", "<undef,6,0>" );
is( leftpad("foo"), "foo", "foo, <undef>" );
is( leftpad( "§¶•\x{1f4a9}", 6 ), "  §¶•\x{1f4a9}", "§¶•\x{1f4a9}, 6" );

# Adapted from GH#1
is( leftpad( "input", 9,  "|-" ), "||||input", "Double-width pad-string" );
is( leftpad( "input", 7,  "" ),   "  input",   "Padding with empty pad char" );
is( leftpad( "input", 0,  "|-" ), "input",     "Padding to zero-width" );
is( leftpad( "input", -1, "|-" ), "input",     "Padding to negative-width" );

done_testing;
#
# This file is part of LeftPad
#
# This software is Copyright (c) 2016 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
