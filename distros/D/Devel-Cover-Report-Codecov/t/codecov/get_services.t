use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;
use Test::Mock::Guard;

use t::Util;
use Devel::Cover::Report::Codecov;

sub get_services {
    Devel::Cover::Report::Codecov::get_services(@_);
}

subtest basic => sub {
    my $guard = mock_guard('Devel::Cover::Report::Codecov', {
        # Module::Find
        findallmod => sub {
            my $pkg = shift;
            is $pkg, 'Devel::Cover::Report::Codecov::Service';

            my $default1 = Test::MockObject->new;
            $default1->set_isa('Default');

            my $default2 = Test::MockObject->new;
            $default2->set_isa('Default');
            $default2->mock(fallback => sub { 0 });

            my $fallback = Test::MockObject->new;
            $fallback->mock(fallback => sub { 1 });
            $fallback->set_isa('Fallback');

            return ($default1, $fallback, $default2);
        },
    });

    my @services = get_services('Devel::Cover::Report::Codecov');

    is @services, 3;
    ok $services[0]->isa('Default');
    ok $services[1]->isa('Default');
    ok $services[2]->isa('Fallback');
};

done_testing;
