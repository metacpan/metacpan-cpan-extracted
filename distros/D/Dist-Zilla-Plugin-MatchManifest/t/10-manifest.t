#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-manifest.t
# Copyright 2010 Christopher J. Madsen
#
# Test MatchManifest plugin
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 14; # done_testing
use Test::Fatal 0.003;

use Test::DZil 'Builder';

sub new_tzil
{
  my $manifest = shift || [];

  $manifest = manifest(@$manifest);

  my $tzil = Builder->from_config(
    { dist_root => 't/corpus/DZT' },
    {
      add_files => {
        $manifest ? ('source/MANIFEST' => $manifest) : (),
        map {; "source/$_" => '' } @_,
      },
    },
  );

  return ($tzil, $manifest);
} # end new_tzil

sub manifest
{
  join("\n", @_) . "\n";
} # end manifest

my $abortedRE = qr/Aborted because of MANIFEST mismatch/;

my @files = qw( MANIFEST Makefile.PL dist.ini lib/DZT/Sample.pm );

{
  my ($tzil) = new_tzil;

  like(exception { $tzil->build }, $abortedRE, "aborts by default");
}

{
  my ($tzil, $before) = new_tzil(\@files);

  is(exception { $tzil->build }, undef, "succeeds when MANIFEST correct");

  is($tzil->slurp_file('source/MANIFEST'), $before, "MANIFEST unchanged");
}

{
  my ($tzil, $before) = new_tzil(\@files, 'README');

  like(exception { $tzil->build }, $abortedRE, "README not in MANIFEST aborts");

  ok((scalar grep /^\+README/m, @{ $tzil->log_messages }),
     'diff shows README');

  is($tzil->slurp_file('source/MANIFEST'), $before, "MANIFEST unchanged");
}

{
  my ($tzil, $before) = new_tzil(\@files, 'README');

  $tzil->chrome->set_response_for("Update MANIFEST?", 'y');

  is(exception { $tzil->build }, undef, "README no abort");

  ok((scalar grep /^\+README/m, @{ $tzil->log_messages }),
     'diff shows README again');

  my $after = manifest(sort @files, 'README');

  is($tzil->slurp_file('source/MANIFEST'), $after, "README added to MANIFEST");

  is($tzil->slurp_file('build/MANIFEST'),  $after,
     "README added to built MANIFEST");
}

{
  my ($tzil, $before) = new_tzil(["'with space'", @files], 'with space');

  is(exception { $tzil->build }, undef, "with space no abort");

  is($tzil->slurp_file('source/MANIFEST'), $before, "with space no change");
}

{
  my ($tzil, $before) = new_tzil(["'file\\'s_apostrophe'", @files],
                                 "file's_apostrophe");

  is(exception { $tzil->build }, undef, "with apostrophe no abort");

#  print "$_\n" for @{ $tzil->log_messages };

  is($tzil->slurp_file('source/MANIFEST'), $before, "with apostrophe no change");
}

done_testing;
