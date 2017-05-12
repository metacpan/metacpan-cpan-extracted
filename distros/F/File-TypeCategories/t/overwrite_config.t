#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use File::TypeCategories;
use File::chdir;

$CWD = 't';
delete $ENV{HOME};
$ENV{USERPROFILE} = '../config';

files_ok();
done_testing();

sub files_ok {
    my $files = File::TypeCategories->new();
    my @ok_files = qw{
        /blah/file
        /blah/file~other
        /blah/logo
        /blah/test.t
        .
    };

    for my $file (@ok_files) {
        ok($files->file_ok($file), $file);
    }

    return;
}
