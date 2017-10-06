use strict;
use warnings FATAL => 'all';
use utf8;

use Test::Mock::Guard;
use Test::Mock::Time;
use Test::MockObject;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

subtest 'without retry' => sub {
    my $url = Test::MockObject->new;
    my $res = Test::MockObject->new;
    my $ok  = { ok => 1 };

    my $guard = mock_guard('Devel::Cover::Report::Codecov', {
        send_report_once => sub {
            is $_[0], $url;
            is $_[1], $res;
            return $ok;
        },
    });

    subtest 'n_times = 0' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 0;
        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ok;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1;
    };

    subtest 'n_times = 1' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 1;
        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ok;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1 + 1;
    };

    subtest 'n_times = 5' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 5;
        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ok;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1 + 1 + 1;
    };
};

subtest 'with retry' => sub {
    my $url = Test::MockObject->new;
    my $res = Test::MockObject->new;
    my $ok  = { ok => 1 };
    my $ng  = { ok => 0 };

    my $count = 0;
    my $guard = mock_guard('Devel::Cover::Report::Codecov', {
        send_report_once => sub {
            is $_[0], $url;
            is $_[1], $res;

            $count++;
            return $count < 5 ? $ng : $ok;
        },
    });

    subtest 'n_times = 0' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 0;

        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ng;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1;
    };

    $count = 0;
    subtest 'n_times = 3' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 3;

        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ng;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1 + 3;
    };

    $count = 0;
    subtest 'n_times = 5' => sub {
        local $Devel::Cover::Report::Codecov::RETRY_TIMES = 5;

        my $result = Devel::Cover::Report::Codecov::send_report($url, $res);
        is $result, $ok;
        is $guard->call_count('Devel::Cover::Report::Codecov', 'send_report_once'), 1 + 3 + 5;
    };
};

done_testing;
