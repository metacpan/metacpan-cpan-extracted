package Devel::Cover::Report::Codecov::Service::Shippable;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{SHIPPABLE};
}

sub configuration {
    return {
        service      => 'shippable',
        build        => $ENV{BUILD_NUMBER},
        build_url    => $ENV{BUILD_URL},
        pull_request => $ENV{PULL_REQUEST},
        slug         => $ENV{REPO_NAME},
        commit       => $ENV{COMMIT},
    };
}

1;
__END__
