#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;

require File::Copy::NoClobber;

use t::lib::TestUtils;

my($fh,$fn) = testfile(undef,SUFFIX => ".txt");

my $fp = File::Copy::NoClobber::filename_with_sprintf_pattern($fn);

isnt $fn, $fp, "filename with counter pattern is different";
isnt $fp, sprintf( $fp, 1 ),
    "updating counter changes the filename";

my $fn2 = "foo bar %%% baz";
my $fp2 = sprintf File::Copy::NoClobber::filename_with_sprintf_pattern($fn2), 1;

isnt $fn2, $fp2, "no suffix filename with %'s seems ok";
like $fp2, qr/$fn2/,
    "% in filename does not mess things up";

done_testing;
