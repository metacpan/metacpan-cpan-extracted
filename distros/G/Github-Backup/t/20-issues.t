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
        token    => $ENV{GITHUB_TOKEN},
        dir      => 't/backup',
        _clean   => 1
    );

    $o->limit(10);
    $o->issues;

    is -d 't/backup/issues/berrybrew', undef, "before finish(), backup dir doesn't exist yet";

    $o->finish;

    is -d 't/backup/issues/berrybrew', 1, "issues have been saved, and finish() did the right thing";
    is -e 't/backup/issues/berrybrew/open/1022065182', 1, "issue correctly saved in open directory";
    is -e 't/backup/issues/berrybrew/closed/979504175', 1, "issue correctly saved in closed directory";
}

done_testing();
