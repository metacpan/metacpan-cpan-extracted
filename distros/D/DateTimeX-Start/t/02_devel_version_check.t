#!perl

# Expected to be run from ../ (make test) or ../blib/ (make disttest)

use strict;
use warnings;

use Test::More;

BEGIN {
   if ($ENV{DEVEL_TESTS}) {
      plan tests => 3;
   } else {
      plan skip_all => "Version checks are only performed when DEVEL_TESTS=1";
   }
}

sub slurp_file {
   my ($qfn) = @_;
   open(my $fh, '<', $qfn)
      or die("Can't open \"$qfn\": $!\n");

   local $/;
   return <$fh>;
}

{
   my $base_file    = slurp_file('lib/DateTimeX/Start.pm');
   my $changes_file = slurp_file('Changes');

   my ($version) = $base_file =~ /\bqv\('v([^']*)'\)/
      or die("Can't find version\n");

   my @parts = split(/\./, $version);

   my ($pod_version) = $base_file =~ /^Version (\S+)/m
      or die("Can't find version in POD\n");

   my ($changes_version) = $changes_file =~ /^([0-9]\S*)/m
      or die("Can't find version in Changes file\n");

   is($pod_version, $version, "Version in POD matches actual version");

   ok($parts[1] % 2 == 0, "Version is a release version");

   is($changes_version, $version, "Version in Changes file matches actual version");
}
