#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Test::More;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

use Config;
plan skip_all => "This test requires gcc" unless $Config{cc} =~ m/(^|-)gcc$/;

ok( !$cc->try_find_cflags_for(
      source => "int main(void) { int nums[] = { [0] = 123 }; return 0; }",
      cflags => [ [qw( -std=c89 -pedantic-errors )] ],
   ), 'C99 program does not compile with only -std=c89' );

ok( $cc->try_find_cflags_for(
      source => "int main(void) { int nums[] = { [0] = 123 }; return 0; }",
      cflags => [ [qw( -std=c99 -pedantic-errors )] ],
   ), 'C99 program compiles with -std=c99' );

ok( scalar( grep { m/^-std=c99$/ } @{ $cc->extra_compiler_flags } ),
   '-std=c99 now appears in extra_compiler_flags' );

done_testing;
