use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Capture::Tiny qw/capture/;
use CPAN::Meta; # needed for missing prereq detection test
use Dist::Zilla::Tester;
use File::pushd qw/pushd/;
use File::Spec;
use Path::Tiny;
use Test::Harness;

my $test_file = File::Spec->catfile(qw(t 00-report-prereqs.t));
my $root      = 'corpus/DZ';

# Adapted from DZP-CheckChangesHasContent
sub capture_test_results {
    my $build_dir      = shift;
    my $test_file_full = File::Spec->catfile( $build_dir, $test_file );
    my $wd             = pushd $build_dir;
    return capture {
        # I'd use TAP::Parser here, except the docs are horrid.
        local $ENV{HARNESS_VERBOSE} = 1;
        Test::Harness::execute_tests( tests => [$test_file_full] );
    };
}

{
    my $tzil = Dist::Zilla::Tester->from_config( { dist_root => $root }, );
    ok( $tzil, "created test dist" );

    $tzil->build_in;

    {
        my $build_dir = path($tzil->tempdir)->child('build');
        my $wd = pushd( $build_dir );
        capture { system( $^X, 'Makefile.PL' ) }; # create MYMETA.json
    }

    my ( $out, $err, $total, $failed ) = capture_test_results( $tzil->built_in );
    is( $total->{ok}, 1, 'test passed' )
      or diag "STDOUT:\n", $out, "STDERR:\n", $err, "\n";
    like( $err, qr/Versions for all modules listed in (?:MY)?META/,
        "Saw report header" );
    like( $err, qr/\bFile::Basename\b/, "prereq reported" );
    like( $err, qr/\bAn::Extra::Module::That::Causes::Problems\b/, "module included" );
    like(
        $err,
        qr/\bAn::Extra::Module::That::Causes::More::Problems\b/,
        "multiple modules included"
    );
    unlike( $err, qr/\bSecretly::Used::Module\b/, "module excluded" );
    like(
        $err,
        qr/\bWARNING\b.*The following.*Missing::Prereq is not installed\b/s,
        "warning issued when missing prereqs detected"
    );
}

done_testing;
#
# This file is part of Dist-Zilla-Plugin-Test-ReportPrereqs
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
