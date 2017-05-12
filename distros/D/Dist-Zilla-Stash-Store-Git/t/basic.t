use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Dist::Zilla::Stash::Store::Git;
use Dist::Zilla::Role::GitStore::Consumer;
use Dist::Zilla::Role::GitStore::ConfigProvider;
use Dist::Zilla::Role::GitStore::ConfigConsumer;

validate_class 'Dist::Zilla::Stash::Store::Git' => (
    does       => [ 'Dist::Zilla::Role::Stash' ],
    attributes => [
        'config',
        'tags',
        'git__wrapper_class',
        'git__raw__repository_class',
        'repo_wrapper' => {

            reader   => 'repo_wrapper',
            writer   => undef,
            accessor => undef,
            builder  => '_build_repo_wrapper',
            lazy     => 1,
        },
        repo_raw => {

            reader   => 'repo_raw',
            writer   => undef,
            accessor => undef,
            builder  => '_build_repo_raw',
            lazy     => 1,
        },
    ],
);

validate_role 'Dist::Zilla::Role::GitStore::Consumer' => (
    required_methods => [],
    attributes       => [

        _git_store => {

            reader   => '_git_store',
            writer   => undef,
            accessor => undef,
            lazy     => 1,
            builder  => '_build__git_store',
        },
    ],
);

validate_role 'Dist::Zilla::Role::GitStore::ConfigConsumer' => (
    does             => [ 'Dist::Zilla::Role::GitStore::Consumer' ],
    required_methods => [ 'gitstore_config_required'              ],
);

validate_role 'Dist::Zilla::Role::GitStore::ConfigProvider' => (
    required_methods => [ 'gitstore_config_provided' ],
);

done_testing;
