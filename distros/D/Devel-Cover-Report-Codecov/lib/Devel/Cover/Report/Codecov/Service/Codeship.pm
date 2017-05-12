package Devel::Cover::Report::Codecov::Service::Codeship;
use strict;
use warnings;
use utf8;

sub detect {
    return defined $ENV{CI_NAME} && $ENV{CI_NAME} eq 'codeship';
}

sub configuration {
    return {
        service   => 'codeship',
        build     => $ENV{CI_BUILD_NUMBER},
        build_url => $ENV{CI_BUILD_URL},
        commit    => $ENV{CI_COMMIT_ID},
        branch    => $ENV{CI_BRANCH},
    };
}

1;
__END__
