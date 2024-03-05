#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

ok( !dies { $cc->assert_compile_run( source => "int main(void) { return 0; }\n", diag => "OK source" ); },
   'Trivial C program'
);

like(
   dies { $cc->assert_compile_run( source => "int foo bar splot\n", diag => "broken source" ); },
   qr/^OS unsupported - broken source$/,
   'Broken C program does not compile and run'
);

done_testing;
