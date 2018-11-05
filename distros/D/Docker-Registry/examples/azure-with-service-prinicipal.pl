#!/usr/bin/env perl

use Data::Dumper;
use Docker::Registry::Azure;

my $REPO_NAME = $ENV{REPO_NAME} or die "Please establish ENV REPO_NAME";

die "Please define ENV AZURE_CLIENT_ID AZURE_SECRET_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID"
  if (not defined $ENV{ AZURE_CLIENT_ID } or
      not defined $ENV{ AZURE_SECRET_ID } or
      not defined $ENV{ AZURE_TENANT_ID } or
      not defined $ENV{ AZURE_SUBSCRIPTION_ID });

my $repo = $ARGV[0];

my $r = Docker::Registry::Azure->new(
  name => $REPO_NAME,
);

if (defined $repo) {
  print Dumper($r->repository_tags(repository => $repo));
} else {
  my $repos = $r->repositories;
  print Dumper($repos);

  foreach my $repo_name (@{ $repos->repositories }) {
    print Dumper($r->repository_tags(repository => $repo_name));
  }
}
