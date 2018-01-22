package Devel::Cover::Report::Codecov::Service::Bitrise;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{BITRISE_IO} ? 1 : 0;
}

sub configuration {
    # http://devcenter.bitrise.io/faq/available-environment-variables/
    return {
        service   => 'bitrise',
        branch    => $ENV{BITRISE_GIT_BRANCH},
        build     => $ENV{BITRISE_BUILD_NUMBER},
        build_url => $ENV{BITRISE_BUILD_URL},
        pr        => $ENV{BITRISE_PULL_REQUEST},
        $ENV{GIT_CLONE_COMMIT_HASH} ?
            (commit => $ENV{GIT_CLONE_COMMIT_HASH}) : (),
    };
}

1;
__END__
