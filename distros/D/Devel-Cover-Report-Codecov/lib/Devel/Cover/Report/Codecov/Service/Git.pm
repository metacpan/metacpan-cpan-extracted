package Devel::Cover::Report::Codecov::Service::Git;
use strict;
use warnings;
use utf8;

sub detect {
    require Capture::Tiny;
    Capture::Tiny->import('capture');

    my (undef, undef, $r) = capture(sub {
        system('git rev-parse --is-inside-work-tree');
    });

    return $r == 0;
}

sub configuration {
    my $branch = `git rev-parse --abbrev-ref HEAD`;
    my $commit = `git rev-parse HEAD`;

    chomp $branch;
    chomp $commit;

    return {
        branch => $branch eq 'HEAD' ? 'master' : $branch,
        commit => $commit,
    };
}

sub fallback { 1 }

1;
