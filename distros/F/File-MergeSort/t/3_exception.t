#!/usr/bin/perl

use 5.006;
use warnings;
use strict;

#
# TODO: check for and catch errors when input is not sorted correctly.
# This is known to fail, but the user is warned about this in the docs.
# Don't test here, it'll only break the install.
#

my $have_io_zlib;

BEGIN {
    eval "require IO::Zlib";
    unless ($@) {
        require IO::Zlib;
        $have_io_zlib++;
    }
}

use Test::More 'no_plan';

BEGIN { use_ok('IO::File') };         # test 1
BEGIN { use_ok('File::MergeSort') };  # test 2

my @files = qw( t/1 t/2 t/3 t/bad_order);
my $coderef = sub { my $line = shift; substr($line,0,2); };

my $m;

eval {
    $m = File::MergeSort->new( \@files );
};

ok($@); # test 3, missing arg.

eval {
    $m = File::MergeSort->new( $coderef );
};

ok($@); # test 4, missing arg.

eval {
    $m = File::MergeSort->new( $coderef, \@files );
};

ok($@); # test 5, bad arg order

eval {
    $m = File::MergeSort->new( [], $coderef );
};

ok($@); # test 6, empty file list

eval {
    $m = File::MergeSort->new( [ "t/no_file" ], $coderef );
};

ok($@); # test 7, nonexistent file.

eval {
    $m = File::MergeSort->new( @files, $coderef );
};

ok($@); # test 8 - array, not array ref.

unless ($have_io_zlib) {
    my @files = qw( t/1 t/2.gz);

    eval {
	$m = File::MergeSort->new( \@files, $coderef );
    };

    ok($@); # test 9 - only if IO::Zlib not installed.
}
