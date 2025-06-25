#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use File::lchown qw( lchown );
use POSIX qw( ENOENT );

my $testlink = "testlink";
unlink $testlink if -l $testlink;

my $missing = "notexist";
$missing .= "X" while -e $missing; # Just in case

is( lchown( $<, $(, $missing ), 0, 'lchown() a non-existent file returns 0' );
is( $!+0, ENOENT, 'lchown() a non-existent file sets \$! == ENOENT' );

# Hard to know for sure what I can do here, but hopefully I'm in at least 2
# groups so I should at least be able to lchown() a symlink into one of my
# supplimentary groups

SKIP: {
   my @groups = grep { $_ != $( } split ' ', $);
   skip "Not enough additional groups", 2 unless @groups;

   symlink( "target", $testlink ) or die "Cannot symlink() - $!";

   is( lchown( -1, $groups[0], $testlink ), 1, 'lchown() returns 1 success' );

   is( ( lstat $testlink )[5], $groups[0], 'Symlink now has new group' );
}

unlink $testlink;

done_testing;
