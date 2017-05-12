use strict;
use warnings;
use Test::More;
use File::Find::Rule;

my @files = File::Find::Rule->name('*.pm')->in('lib');
plan tests => @files + 0;

for (@files) {
  next if /Tutorial.pm/;
  s/^lib.//;
  s/.pm$//;
  s{[\\/]}{::}g;

  ok(
    eval "require $_; 1",
    "loaded $_ with no problems",
  ) or diag $@;
}
