use t::boilerplate;

# This file was part of Dist-Zilla-Plugin-Test-ReportPrereqs
# This software is Copyright (c) 2012 by David Golden.
# This is free software, licensed under:
#   The Apache License, Version 2.0, January 2004

use Test::More 0.96;

use Capture::Tiny qw( capture );
use CPAN::Meta; # Needed for missing prereq detection test
use Dist::Zilla::Tester;
use File::pushd   qw( pushd );
use File::Spec;
use Test::Harness;

my $root      = 'corpus/DZ';
my $test_file = File::Spec->catfile( qw( t 00report-metadata.t ) );

# Adapted from DZP-CheckChangesHasContent
sub capture_test_results {
   my $build_dir      = shift;
   my $test_file_full = File::Spec->catfile( $build_dir, $test_file );
   my $wd             = pushd $build_dir;

   return capture { # I'd use TAP::Parser here, except the docs are horrid.
      local $ENV{HARNESS_VERBOSE} = 1;
      Test::Harness::execute_tests( tests => [ $test_file_full ] );
   };
}

{  my $tzil = Dist::Zilla::Tester->from_config( { dist_root => $root }, );

   ok $tzil, 'Created test dist'; $tzil->build_in;

   {  my $wd = pushd( File::Spec->catdir( $tzil->tempdir, 'build' ) );
      capture { system( $^X, 'Build.PL' ) }; # create MYMETA.json
   }

   my ($out, $err, $total, $failed) = capture_test_results( $tzil->built_in );

   is( $total->{ok}, 1, 'Test passed' )
      or diag "STDOUT:\n", $out, "STDERR:\n", $err, "\n";
   like $err, qr{Versions for all modules listed in (?:MY)?META},
        'Saw report header';
   like $err, qr{\bFile::Basename\b}, 'Prereq reported';
   like $err,
        qr{\bAn::Extra::Module::That::Causes::Problems\b}, 'Module included';
   like $err,
        qr{\bAn::Extra::Module::That::Causes::More::Problems\b},
        'Multiple modules included';
   unlike $err, qr{\bSecretly::Used::Module\b}, 'Module excluded';
   like $err,
        qr{\bWARNING\b.*The following.*Missing::Prereq is not installed\b}s,
        'Warning issued when missing prereqs detected';
}

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
