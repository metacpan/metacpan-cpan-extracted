#!/usr/bin/perl
# $Id: 03-iso-latin1.t 19 2012-08-29 06:19:44Z andrew $

use strict;
use warnings;

use Test::More tests => 4;

use blib;
use LaTeX::Encode;

is_conversion_ok('24', 'dollar sign',  '\\$');
is_conversion_ok('a2', 'cent sign',    '{\\textcent}');
is_conversion_ok('a3', 'pound sign',   '{\\textsterling}');
is_conversion_ok('a5', 'yen sign',     '{\\textyen}');



sub is_conversion_ok {
    my ($code, $name, $translation) = @_;

    my $codestr = sprintf('\x%s', $code); 
    $codestr = eval "\"$codestr\"";

    is(latex_encode("$name: $codestr."), "$name: $translation.", "0x$code - $name");
    return;
}
