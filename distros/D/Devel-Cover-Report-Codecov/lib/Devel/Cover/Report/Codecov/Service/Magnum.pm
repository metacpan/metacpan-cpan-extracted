package Devel::Cover::Report::Codecov::Service::Magnum;
use strict;
use warnings;
use utf8;

sub detect {
    return defined $ENV{MAGNUM} && $ENV{MAGNUM} eq 'true';
}

sub configuration {
    return {
        service => 'magnum',
        branch  => $ENV{CI_BRANCH},
        build   => $ENV{CI_BUILD_NUMBER},
        commit  => $ENV{CI_COMMIT},
    };
}

1;
__END__
