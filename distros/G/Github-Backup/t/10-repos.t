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
    );

    $o->repos;

    is -e $o->dir, 1, "backup dir exists";
    is -d $o->dir, 1, "backup dir is a dir";
}

done_testing();
