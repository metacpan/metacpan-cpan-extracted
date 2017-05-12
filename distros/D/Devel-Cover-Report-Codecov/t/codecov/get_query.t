use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;

use t::Util;
use Devel::Cover::Report::Codecov;

sub get_query {
    Devel::Cover::Report::Codecov::get_query(@_);
}

sub _make_service {
    my $service = Test::MockObject->new;
    $service->mock(detect => sub { 1 });
    $service->mock(configuration => sub { { key => 'value' } });

    return $service;
}

subtest 'if has token' => sub {
    local $ENV{CODECOV_TOKEN} = 'token';

    cmp_deeply
        get_query(_make_service),
        { key => 'value', token => 'token' };
};

subtest 'if has not token' => sub {
    local %ENV = ();

    cmp_deeply
        get_query(_make_service),
        { key => 'value' };
};

done_testing;
