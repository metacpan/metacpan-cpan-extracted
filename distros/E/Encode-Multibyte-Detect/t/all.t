#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok('Encode::Multibyte::Detect');
}

use Encode::Multibyte::Detect qw(:all);

no warnings 'utf8';

use utf8;

my @strings = (
    # correct utf-8
    {text => "проверка"                                         , enc => 'utf-8', valid => 1, strict => 1},
    # 7-bit
    {text => "test"                                             , enc => 'utf-8', valid => 0, strict => 0},
    # bad unicode char
    {text => "проверк\x{d800}"                                  , enc => 'utf-8', valid => 1, strict => 0},
);

no utf8;

push @strings, (
    # 7-bit
    {text => 'test',                                            , enc => '7-bit', valid => 1},
    # 8-bit
    {text => "проверка",                                        , enc => '7-bit', valid => 0},

    # correct utf-8
    {text => "проверка"                                         , enc => 'utf-8', valid => 1, strict => 1},
    # 7-bit
    {text => "test"                                             , enc => 'utf-8', valid => 0, strict => 0},
    # bad unicode char
    {text => "\x{fb}\x{bf}\x{bf}\x{bf}\x{bf}"                   , enc => 'utf-8', valid => 1, strict => 0},
    # unfinished sequence
    {text => "проверк\x{d0}"                                    , enc => 'utf-8', valid => 0, strict => 0},
    # broken sequence
    {text => "проверк\x{d0}0"                                   , enc => 'utf-8', valid => 0, strict => 0},
);

for my $string (@strings) {
    if ($string->{enc} eq '7-bit') {
        if ($string->{valid}) {
            ok(detect($string->{text}) eq '', "detected encoding is empty");
            ok(is_7bit($string->{text}), "is 7-bit");
        }
        else {
            ok(!is_7bit($string->{text}), "is not 7-bit");
        }
    }
    elsif ($string->{enc} eq 'utf-8') {
        if ($string->{strict}) {
            ok(detect($string->{text}) eq 'utf-8', "detected encoding is utf-8");
            ok(detect($string->{text}, strict => 1) eq 'utf-8', "detected encoding is utf-8");

            ok(is_valid_utf8($string->{text}), "is valid utf-8");
            ok(is_strict_utf8($string->{text}), "is strict utf-8");
        }
        elsif ($string->{valid}) {
            ok(detect($string->{text}) eq 'utf-8', "detected encoding is utf-8");
            ok(detect($string->{text}, strict => 1) ne 'utf-8', "detected encoding is not utf-8");

            ok(is_valid_utf8($string->{text}), "is valid utf-8");
            ok(!is_strict_utf8($string->{text}), "is not strict utf-8");
        }
        else {
            ok(detect($string->{text}) ne 'utf-8', "detected encoding is not utf-8");
            ok(detect($string->{text}, strict => 1) ne 'utf-8', "detected encoding is not utf-8");

            ok(!is_valid_utf8($string->{text}), "is not valid utf-8");
            ok(!is_strict_utf8($string->{text}), "is not strict utf-8");
        }
    }
}

1;
