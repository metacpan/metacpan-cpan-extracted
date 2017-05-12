package Devel::Cover::Report::Codecov::Service::Mercurial;
use strict;
use warnings;
use utf8;

sub detect {
    require Capture::Tiny;
    Capture::Tiny->import('capture');

    my (undef, undef, $r) = capture(sub {
        system('hg root');
    });

    return $r == 0;
}

sub configuration {
    my $branch = `hg branch`;
    my $commit = `hg id -i --debug`;

    chomp $branch;
    chomp $commit;

    $commit =~ s/x//;

    return {
        branch => $branch,
        commit => $commit,
    };
}

sub fallback { 1 }

1;
