#!/usr/bin/env perl

use strict;
use warnings;

use Cwd 'abs_path';
use File::Basename;
use Test::More;

my $fullpath = join "/", abs_path, $0;
my $testdir = dirname $fullpath;
my $testfile = join "/", $testdir , "testfile";

use_ok( 'File::Details' );

my $filedetails = File::Details->new( $testfile );

# default now is md5sum

SKIP: {
    eval { require Digest::MD5 };

    skip "Digest::MD5 not available", 1 if $@;

    is( $filedetails->hash, "5dd39cab1c53c2c77cd352983f9641e1", "md5sum" );

}
done_testing;

__END__
5dd39cab1c53c2c77cd352983f9641e1  t/testfile
