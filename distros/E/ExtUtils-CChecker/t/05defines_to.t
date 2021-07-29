#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Test::More;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new(
   defines_to => "test-config.h",
);

END { -e "test-config.h" and unlink "test-config.h"; }

ok( defined $cc, 'defined $cc' );
isa_ok( $cc, "ExtUtils::CChecker", '$cc' );

$cc->try_compile_run(
   source => "int main(void) { return 0; }\n",
   define => "HAVE_C",
);

is_deeply( $cc->extra_compiler_flags, [], 'extra_compiler_flags does not have -D' );

ok( -e "test-config.h", 'test-config.h exists' );

open my $fh, "<", "test-config.h" or die "Cannot read test-config.h - $!";
is( scalar <$fh>, "#define HAVE_C /**/\n", 'test-config.h has #define HAVE_C' );

done_testing;
