#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);

use_ok('File::Tempdir');

{
    my $tempdir;
    {
        my $tdo = File::Tempdir->new();
        isa_ok($tdo, 'File::Tempdir');
        $tempdir = $tdo->name();
        ok(defined($tempdir), 'name() works');
        ok(-d $tempdir, 'directory has been created');
    }
    ok(! -d $tempdir, 'directory has been trashed by destroy');
}

# now testing with a dir it should not touch
{
    my $tempdir = tempdir();
    {
        my $tdo = File::Tempdir->new($tempdir);
        isa_ok($tdo, 'File::Tempdir');
        is($tdo->name, $tempdir, 'return properly the dir name');
    }
    ok(-d $tempdir, 'directory has not been trashed by destroy');
}

