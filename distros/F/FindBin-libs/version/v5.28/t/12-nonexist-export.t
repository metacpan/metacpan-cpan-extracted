#!/usr/bin/perl

package Testophile;

use v5.8;

no warnings;    # avoid extraneous nastygrams about qw

use Symbol;
use Test::More;
use File::Temp  qw( tempfile );

SKIP:
{
    require_ok 'FindBin::libs';

    2.0 < FindBin::libs->VERSION
    or skip "Test for new version", 2;

    $\ = "\n";
    $, = "\n\t";

    my @argz    = qw( base=frobnicate export=foobar scalar );

    note "Import args:\n", explain \@argz;

    FindBin::libs->import( @argz );

    eval '{use strict; ! defined $foobar}';

    ok ! $@ , 'Undef $foobar exported';
}

done_testing;

exit 0;
