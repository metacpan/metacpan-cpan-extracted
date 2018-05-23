#!/usr/bin/env perl

use Data::Dumper;
use Docker::Registry::V2;
use Docker::Registry::ECR;
use Docker::Registry::Auth::ECR;

my $repo = $ARGV[0];

my $r = Docker::Registry::ECR->new(
  account_id => '000000000000',
  region => 'eu-central-1',
);
$r->caller->debug(1);

if (defined $repo) {
  print Dumper($r->repository_tags(repository => $repo));
} else {
  my $repos = $r->repositories;
  print Dumper($repos);

  foreach my $r (@{ $repos->repositories }) {
    print Dumper($r->repository_tags(repository => $r));
  }
}
