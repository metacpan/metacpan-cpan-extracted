#!/usr/bin/perl -w

use File::Grep qw( fgrep fmap fdo );
use Test::More tests=>11;

my @files = qw( t/test.txt t/test2.txt );

# Void context:
if ( fgrep { /Bob/ } @files ) {
	pass "Void context";
} else {
	fail "Void context";
}

if ( fgrep { /Steve/ } @files ) {
	fail "Void context";
} else {
	pass "Void context";
}

my $count = fgrep { /Bob/ } @files;

is( $count, 5, "Scalar context" );

my @matches = fgrep { /Bob/ } @files;

is( $matches[0]->{ count }, 5, "Hash context" );
is( $matches[1]->{ count }, 0, "Hash context" );

@matches = fgrep { /\WBob\W/ } @files;

is( $matches[0]->{ count }, 4, "Hash context" );

my @lced = fmap { chomp; lc; } @files;
is( "--$lced[4]--", "--by this test.  if there are--", "Mapping" );


open FILE1, "<t/test.txt" or die $!;
my $f1 = \*FILE1;
open FILE2, "<t/test2.txt" or die $!;
my $f2 = \*FILE2;

my $count2 = fgrep { /Bob/ } $f1, $f2;
is ( $count2, 5, "Filehandle context" );

close $f1;
close $f2;

open FILE2, "<t/test2.txt" or die $!;
my $f3 = \*FILE2;
my $count3 = fgrep { /Bob/ } $f3;
is ( $count3, 0, "Filehandle context" );
close $f3;

my $count4 = fgrep { /Bob/ } [ qw( wrong argument here ) ];
is ( $count4, 0, "Illegal context" );

my $words = 0;
fdo { my @w = split /\s+/, $_;
      $words += scalar @w } @files;
is ( $words, 68, "fdo" );



close $f1;
close $f2;
