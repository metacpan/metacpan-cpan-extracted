#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use File::ShouldUpdate qw/ should_update /;

use Path::Tiny qw/ path tempdir tempfile cwd /;

my $dir = tempdir();

my $fh = $dir->child("foo.txt");

$fh->spew_raw("foo");
my $dep2 = $dir->child("dep2.txt");

$dep2->spew_raw("dep2");

my $new = $dir->child("new.txt");

{
    # TEST
    ok(
        should_update( $new, ":", $fh, $dep2 ),
        'should_update on non-existent target file'
    );
    $new->spew_raw("updated");

    # TEST
    ok(
        scalar( !should_update( $new, ":", $fh, $dep2 ) ),
        'should_update on updated file.',
    );
}
