#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More tests => 2;
use Path::Tiny qw/ path tempdir tempfile cwd /;

use Test::File::IsSorted ();

my $dir = tempdir();

my $GOOD_TEXT = <<'EOF';
a
b
d
j
u
EOF

{
    my $fh = $dir->child('good.txt');
    $fh->spew_raw($GOOD_TEXT);

    my $fh2 = $dir->child('other-input.txt');
    $fh2->spew_raw("aaa\nzy\n");

    # TEST*1
    eval {
        sub {
            Test::File::IsSorted::are_sorted2(
                [ "$fh2", "$fh" ],
                "Filenames are sorted",
            );
            }
            ->();
    };
    my $err = $@;
    ok( $err, "filenames are not sorted" );

    # TEST
    Test::File::IsSorted::are_sorted2(
        [ "$fh", "$fh2" ],
        "Filenames are sorted",
    );
}
