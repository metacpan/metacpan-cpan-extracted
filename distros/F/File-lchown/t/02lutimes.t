#!/usr/bin/perl -w

use strict;

use Test::More;

use File::lchown qw( lutimes );
use POSIX qw( ENOENT );

defined eval { lutimes(undef,undef) } or plan skip_all => "No lutimes()";

plan tests => 4;

my $testlink = "testlink";
unlink $testlink if -l $testlink;

my $missing = "notexist";
$missing .= "X" while -e $missing; # Just in case

is( lutimes( 0, 0, $missing ), 0, 'lutimes() a non-existent file returns 0' );
is( $!+0, ENOENT, 'lutimes() a non-existent file sets \$! == ENOENT' );

symlink( "target", $testlink ) or die "Cannot symlink() - $!";

is( lutimes( 0, 0, $testlink ), 1, 'lutimes() returns 1 success' );

is( ( lstat $testlink )[9], 0, 'Symlink has 1970-01-01 00:00:00 mtime' );

unlink $testlink;
