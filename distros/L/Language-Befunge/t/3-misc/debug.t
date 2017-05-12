#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Language::Befunge::Debug;

use Test::More tests => 3;
use Test::Output;


# debug tests.
stderr_is { debug( "foo\n" ) } '',      'debug disabled by default';
Language::Befunge::Debug::enable();
stderr_is { debug( "bar\n" ) } "bar\n", 'debug warns properly when debug is enabled';
Language::Befunge::Debug::disable();
stderr_is { debug( "baz\n" ) } '',      'debug does not warn when debug is disabled';
