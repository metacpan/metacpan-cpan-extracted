#!perl

use strict;
use warnings;

# This doesn't use Test::More because I don't want to clutter %INC
# with modules that aren't prerequisites.

my $test = 0;

sub ok ($$)
{
  my ($ok, $name) = @_;

  printf "%sok %d - %s\n", ($ok ? '' : 'not '), ++$test, $name;

  return $ok;
} # end ok

END {
  ok(0, 'unknown failure') unless $test;
  print "1..$test\n";
}

sub get_version
{
  my ($package) = @_;

  local $@;
  my $version = eval { $package->VERSION };

  defined $version ? $version : 'undef';
} # end get_version

TEST: {
  ok(open(META, '<META.json'), 'opened META.json') or last TEST;

  while (<META>) {
     last if /^\s*"prereqs" : \{\s*\z/;
  } # end while <META>

  ok(defined $_, 'found prereqs') or last TEST;

  while (<META>) {
    last if /^\s*\},?\s*\z/;
    ok(/^\s*"(.+)" : \{\s*\z/, "found phase $1") or last TEST;
    my $phase = $1;

    while (<META>) {
      last if /^\s*\},?\s*\z/;
      next if /^\s*"[^"]+"\s*:\s*\{\s*\},?\s*\z/;
      ok(/^\s*"(.+)" : \{\s*\z/, "found relationship $phase $1") or last TEST;
      my $rel = $1;

      while (<META>) {
        last if /^\s*\},?\s*\z/;
        ok(/^\s*"([^"]+)"\s*:\s*(\S+?),?\s*\z/, "found prereq $1")
            or last TEST;
        my ($prereq, $version) = ($1, $2);

        next if $phase ne 'runtime' or $prereq eq 'perl';

        my $loaded = eval "require $prereq; $prereq->VERSION($version); 1";
        if ($rel eq 'requires') {
          ok($loaded, "loaded $prereq $version")
              or printf STDERR "\n#    Got: %s %s\n# Wanted: %s %s\n",
                  $prereq, get_version($prereq), $prereq, $version;
        } else {
          ok(1, ($loaded ? 'loaded' : 'failed to load') . " $prereq $version");
        }
      } # end while <META> in prerequisites
    } # end while <META> in relationship
  } # end while <META> in phase

  close META;

  # Print version of all loaded modules:
  if ($ENV{AUTOMATED_TESTING}) {
    print STDERR "# Listing %INC\n";

    my @packages = grep { s/\.pm\Z// and do { s![\\/]!::!g; 1 } } sort keys %INC;

    my $len = 0;
    for (@packages) { $len = length if length > $len }
    $len = 68 if $len > 68;

    for my $package (@packages) {
      printf STDERR "# %${len}s %s\n", $package, get_version($package);
    }
  } # end if AUTOMATED_TESTING
} # end TEST

