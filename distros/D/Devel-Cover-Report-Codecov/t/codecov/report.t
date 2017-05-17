use strict;
use warnings FATAL => 'all';
use utf8;

use JSON::XS;
use Test::MockObject;
use Test::Mock::Guard;
use Capture::Tiny qw/capture_stdout/;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub report {
    Devel::Cover::Report::Codecov::report(@_);
}

subtest 'if service found' => sub {
    my $db      = Test::MockObject->new;
    my $service = Test::MockObject->new;
    $service->mock(detect => sub { 1 });
    $service->mock(configuration => sub { { key => 'value' } });

    my $guard = mock_guard('Devel::Cover::Report::Codecov',
        {
            get_codecov_json => sub {
                my ($file, $_db) = @_;
                is $db, $_db;
                cmp_deeply $file, [ 'lib/Foo.pm', 'lib/Foo/Bar.pm' ];
                return '{"coverage":[]}';
            },

            get_request_url => sub {
                my ($url, $query) = @_;
                is $url, 'http://codecov.io/upload/v2';
                cmp_deeply $query, { key => 'value' };
                return 'http://www.example.com';
            },

            send_report => sub {
                my ($url, $json) = @_;
                is $url, 'http://www.example.com';
                cmp_deeply decode_json($json), { coverage => [] };
                return { ok => 1, message => 'send_report' };
            },

            get_query => sub {
                my $service = shift;
                return $service->configuration;
            },

            get_services => sub {
                my $pkg = shift;
                is $pkg, 'Devel::Cover::Report::Codecov';
                return ($service);
            },
        });

    my $options = {
        file => [ 'lib/Foo.pm', 'lib/Foo/Bar.pm' ],
    };

    my ($stdout) = capture_stdout {
        report('Devel::Cover::Report::Codecov', $db, $options);
    };
    is $stdout, "send_report\n";

    my $pkg = 'Devel::Cover::Report::Codecov';
    is $guard->call_count($pkg, 'get_codecov_json'), 1;
    is $guard->call_count($pkg, 'get_request_url'), 1;
    is $guard->call_count($pkg, 'send_report'), 1;
    is $guard->call_count($pkg, 'get_services'), 1;
};

subtest 'if service not found' => sub {
    dies_ok {
        report('Unknown::Namespace', undef, {});
    };
};

done_testing;
