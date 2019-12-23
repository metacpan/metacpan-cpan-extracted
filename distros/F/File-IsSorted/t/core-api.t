#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More tests => 3;

use Path::Tiny qw/ path tempdir tempfile cwd /;

use File::IsSorted ();

my $dir = tempdir();

my $GOOD_TEXT = <<'EOF';
a
b
d
j
u
EOF

my $BAD_TEXT = <<'EOF';
a
d
b
EOF

{
    open my $fh, '<', \$GOOD_TEXT;
    my $sorter = File::IsSorted->new;

    # TEST
    ok( scalar( $sorter->is_filehandle_sorted( { fh => $fh } ) ),
        "simple fh test" );
}

{
    my $fh = $dir->child('good.txt');
    $fh->spew_raw($GOOD_TEXT);

    my $sorter = File::IsSorted->new;

    # TEST
    ok( scalar( $sorter->is_file_sorted( { path => "$fh", } ) ),
        "simple path test" );
}

{
    my $fh = $dir->child('bad.txt');
    $fh->spew_raw($BAD_TEXT);

    my $sorter = File::IsSorted->new;

    # TEST
    my $verdict;
    eval { $verdict = $sorter->is_file_sorted( { path => "$fh", } ); };
    my $Err = $@;

    like( $Err, qr/less/, "bad input throws" );
}
