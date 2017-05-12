#!/usr/bin/perl
# $Id: 04-utf8.t 27 2012-08-30 19:54:25Z andrew $

use strict;
use warnings;

use blib;
use LaTeX::Encode;
use charnames qw();

use Test::More tests => 3;

is(latex_encode("a\nb"), "a\nb",              'string including newline' );
is(latex_encode("a\rb"), "a\rb",              'string including carriage return' );

is(latex_encode("a\x{f900}b"), "a\\unmatched{f900}b",      'string including an unsupported ideograph' );
