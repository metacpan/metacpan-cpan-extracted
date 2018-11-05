#!/usr/bin/env perl

use Data::Dumper;
use Docker::Registry::Azure;

my $REPO_NAME = $ENV{REPO_NAME} or die "Please establish ENV REPO_NAME";
my $REPO_PASS = $ENV{REPO_PASS} or die "Please establish ENV REPO_PASS";

my $repo = $ARGV[0];

my $r = Docker::Registry::Azure->new(
  name => $REPO_NAME,
  password => $REPO_PASS,
);
$r->caller->debug(1);

if (defined $repo) {
  print Dumper($r->repository_tags(repository => $repo));
} else {
  my $repos = $r->repositories;
  print Dumper($repos);

  foreach my $repo_name (@{ $repos->repositories }) {
    print Dumper($r->repository_tags(repository => $repo_name));
  }
}
