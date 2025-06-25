#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use File::lchown qw( lutimes );
use POSIX qw( ENOENT );

use Time::HiRes;
use constant HAVE_HIRES_LSTAT => $Time::HiRes::VERSION ge 1.9726;

defined eval { lutimes(undef,undef) } or plan skip_all => "No lutimes()";

my $testlink = "testlink";
unlink $testlink if -l $testlink;

my $missing = "notexist";
$missing .= "X" while -e $missing; # Just in case

is( lutimes( 0, 0, $missing ), 0, 'lutimes() a non-existent file returns 0' );
is( $!+0, ENOENT, 'lutimes() a non-existent file sets \$! == ENOENT' );

symlink( "target", $testlink ) or die "Cannot symlink() - $!";

is( lutimes( 0, 0, $testlink ), 1, 'lutimes() returns 1 success' );

is( ( lstat $testlink )[9], 0, 'Symlink has 1970-01-01 00:00:00 mtime' );

if( HAVE_HIRES_LSTAT ) {
   is( lutimes( 123.5, 123.5, $testlink ), 1, 'lutimes() can set fractional' );

   is( ( Time::HiRes::lstat $testlink )[9], 123.5, 'lstat() after lutimes() fractional mtime' );

   is( lutimes( [ 456, 789000 ], [ 456, 789000 ], $testlink ), 1, 'lutimes() can set ARRAY' );

   is( ( Time::HiRes::lstat $testlink )[9], 456.789, 'lstat() after lutimes() ARRAY mtime' );
}

unlink $testlink;

done_testing;
