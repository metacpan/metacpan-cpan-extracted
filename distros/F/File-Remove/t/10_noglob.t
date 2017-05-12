#!/usr/bin/perl

use strict;
use warnings;

use 5.006;

use File::Spec ();
use Cwd (qw/getcwd/);

use File::Path qw/rmtree/;

use Test::More tests => 3;

use File::Remove qw/remove/;

{
    my $dir = File::Spec->rel2abs(
        File::Spec->catdir(
            File::Spec->curdir(), "t", "10_noglob_dir",
        )
    );

    mkdir($dir);

    my $file_path = sub {
        my ($bn) = @_;
        return File::Spec->catfile($dir, $bn);
    };

    my $create_file = sub {
        my ($bn, $contents) = @_;

        open my $fh, '>', $file_path->($bn)
            or die "Cannot create basename '$bn'";
        print {$fh} $contents;
        close ($fh);

        return;
    };

    $create_file->("a", "a contents\n");
    $create_file->("b", "b contents\n");
    $create_file->("c", "c contents\n");

    my $cur_dir = getcwd();

    chdir ($dir);

    remove(\0, +{ glob => 0 }, '*');

    my $is_file = sub {
        my ($bn) = @_;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        return ok (scalar(-e $file_path->($bn)), "$bn was not deleted.");
    };

    # TEST
    $is_file->('a');

    # TEST
    $is_file->('b');

    # TEST
    $is_file->('c');

    chdir ($cur_dir);

    rmtree ($dir);
}

