#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

is( $cc->include_dirs, [], 'include_dirs empty initially' );

$cc->push_include_dirs( "/usr/include/foo" );
is( $cc->include_dirs, [ "/usr/include/foo" ], 'include_dirs after push_include_dirs' );

is( $cc->extra_compiler_flags, [], 'extra_compiler_flags empty initially' );

$cc->push_extra_compiler_flags( "-DHAVE_FOO" );
is( $cc->extra_compiler_flags, [ "-DHAVE_FOO" ], 'extra_compiler_flags after push_extra_compiler_flags' );

is( $cc->extra_linker_flags, [], 'extra_linker_flags empty initially' );

$cc->push_extra_linker_flags( "-lfoo" );
is( $cc->extra_linker_flags, [ "-lfoo" ], 'extra_linker_flags after push_extra_linker_flags' );

done_testing;
