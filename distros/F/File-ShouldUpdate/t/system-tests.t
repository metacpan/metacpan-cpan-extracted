#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use File::ShouldUpdate qw/ should_update should_update_multi /;

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

{
    my $new2     = $dir->child("new--2.pl");
    my $newfiles = [ $new, $new2 ];
    my $deps     = [ $fh,  $dep2 ];
    my $call     = sub {
        return should_update_multi( $newfiles, ":", $deps );
    };

    # TEST
    ok( scalar( $call->() ), 'should_update on non-existent target file' );
    $new->spew_raw("updated");
    $new2->spew_raw("updated");

    # TEST
    ok(
        scalar( !scalar( $call->() ) ),
        'should_update_multi on updated file.',
    );
}
