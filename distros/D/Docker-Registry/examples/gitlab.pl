#!/usr/bin/env perl

use Data::Dumper;
use Docker::Registry::Gitlab;
use Docker::Registry::Auth::Gitlab;

my $repo = $ARGV[0];

my $username = $ENV{ GITLAB_USERNAME } // die "Please set ENV GITLAB_USERNAME";
my $personal_token = $ENV{ GITLAB_TOKEN } // die "Please set ENV GITLAB_TOKEN";

my $r = Docker::Registry::Gitlab->new(
    username => $username,
    access_token => $personal_token,
    defined $repo ? (repo => $repo) : (),
);

$r->caller->debug(1);

if (defined $repo) {
    print Dumper($r->repository_tags(repository => $repo));
}
else {
    my $repos = $r->repositories;
    print Dumper($repos);

    foreach my $r (@{ $repos->repositories }) {
        print Dumper($r->repository_tags(repository => $r));
    }
}
