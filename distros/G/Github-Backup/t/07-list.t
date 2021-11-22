use strict;
use warnings;

use Github::Backup;
use Test::More;

if (! $ENV{AUTHOR_TESTING}){
    plan skip_all => "author test only (set env var AUTHOR_TESTING=1)";
}

if (! $ENV{GITHUB_TOKEN}){
    plan skip_all => "This test requires your Github token to be placed into " .
        "the GITHUB_TOKEN environment variable\n";
}

{ # base

    my $mod = 'Github::Backup';

    my $o = $mod->new(
        api_user => 'stevieb9',
        #        token    => $ENV{GITHUB_TOKEN},
        dir      => 't/backup',
        _clean   => 1,
    );

    my $repos = $o->list;

    is scalar @$repos > 100, 1, "Number of repos ok";

    my @names;

    for my $repo (@$repos) {
        my $name = $repo->{name};
        push @names, $name;
    }

    my $result = grep /^github-backup/, @names;
    is $result, 1, "github-backup in the list of repos ok";
}

done_testing();
