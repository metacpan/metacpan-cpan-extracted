#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $tzil = Builder->from_config({ dist_root => 'corpus/vDZT' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/vDZT.pm'));

my $lib = $tzil->slurp_file('build/lib/vDZT.pm');

my $expected_lib = <<'END LIB';
package vDZT;
our $VERSION = 'v0.1.0'; # VERSION
1;
# ABSTRACT: my abstract
END LIB

is ( $lib, $expected_lib, 'check vDZT.pm' );

done_testing;
