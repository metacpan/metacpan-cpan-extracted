#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Test::More;

use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

is_deeply( $cc->include_dirs, [], 'include_dirs empty initially' );

$cc->push_include_dirs( "/usr/include/foo" );
is_deeply( $cc->include_dirs, [ "/usr/include/foo" ], 'include_dirs after push_include_dirs' );

is_deeply( $cc->extra_compiler_flags, [], 'extra_compiler_flags empty initially' );

$cc->push_extra_compiler_flags( "-DHAVE_FOO" );
is_deeply( $cc->extra_compiler_flags, [ "-DHAVE_FOO" ], 'extra_compiler_flags after push_extra_compiler_flags' );

is_deeply( $cc->extra_linker_flags, [], 'extra_linker_flags empty initially' );

$cc->push_extra_linker_flags( "-lfoo" );
is_deeply( $cc->extra_linker_flags, [ "-lfoo" ], 'extra_linker_flags after push_extra_linker_flags' );

done_testing;
