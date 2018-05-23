#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Docker::Registry::GCE;
use Docker::Registry::Auth::GCEServiceAccount;

my $ce = $ENV{ CLIENT_EMAIL } // die "Please set ENV CLIENT_EMAIL";
my $pk = $ENV{ PRIVATE_KEY } // die "Please set ENV PRIVATE_KEY";
#passing a repo is because sometimes your credentials don't let you list
#the repositories, but you can see the tags of a repo if you know its name
my $repo = $ARGV[0];

my $sa = Docker::Registry::Auth::GCEServiceAccount->new(
  client_email => $ce,
  private_key => $pk,
);

my $r = Docker::Registry::GCE->new(
  auth => $sa,
);

#$r->caller->debug(1);

if (defined $repo) {
  print Dumper($r->repository_tags(repository => $repo));
} else {
  my $repos = $r->repositories;
  print Dumper($repos);

  foreach my $r (@{ $repos->repositories }) {
    print Dumper($r->repository_tags(repository => $r));
  }
}
