#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::Tester tests => 6;
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

    # TEST*6
    check_test(
        sub {
            Test::File::IsSorted::are_sorted(
                [ "$fh", "$fh2" ],
                "Files are sorted",
            );
        },
        +{
            ok   => 1,
            name => "Files are sorted",
        }
    );
}
