#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Dir::Manifest::Slurp qw/ as_lf slurp /;

use Socket qw(:crlf);

use Path::Tiny qw/ path tempdir tempfile cwd /;

{
    # TEST
    is( as_lf("hello\r\nworld"), "hello${LF}world", "as_lf #1" );
}

{
    my $dir = tempdir();

    my $fh = $dir->child("foo.txt");

    $fh->spew_raw("hi\r\nworld");

    # TEST
    is( slurp( $fh, { lf => 1, } ), "hi${LF}world", "slurp works." );
}
