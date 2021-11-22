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

    $o->limit(1);
    $o->repos;

    is -e $o->dir, undef, "backup dir doesn't exist before finish() called ok";

    $o->finish;

    is -e $o->dir, 1, "backup dir exists, and finish() did the right thing";
    is -d $o->dir, 1, "backup dir is a dir";
}

done_testing();
