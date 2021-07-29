#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

ok(
   !exception { $cc->assert_compile_run( source => "int main(void) { return 0; }\n", diag => "OK source" ); },
   'Trivial C program'
);

like(
   exception { $cc->assert_compile_run( source => "int foo bar splot\n", diag => "broken source" ); },
   qr/^OS unsupported - broken source$/,
   'Broken C program does not compile and run'
);

done_testing;
