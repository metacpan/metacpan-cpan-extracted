use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Shippable;

sub configuration {
    return Devel::Cover::Report::Codecov::Service::Shippable->configuration(@_);
}

subtest basic => sub {
    local %ENV = (
        BUILD_NUMBER => 'build_number',
        BUILD_URL    => 'build_url',
        PULL_REQUEST => 'pull_request',
        REPO_NAME    => 'slug',
        COMMIT       => 'commit',
    );

    cmp_deeply
        configuration,
        {
            service      => 'shippable',
            build        => 'build_number',
            build_url    => 'build_url',
            pull_request => 'pull_request',
            slug         => 'slug',
            commit       => 'commit',
        };
};

done_testing;
