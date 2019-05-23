use strict;
use warnings;
use Test::Most;
use Log::Any::Adapter 'Test';
use Time::HiRes 'usleep';
use Log::Timer;

sub assert_log(&$;$) {
    my ($code,$log_re,$name) = @_;
    $name ||= 'event';

    Log::Any::Adapter::Test->clear;

    $code->();

    Log::Any::Adapter::Test->contains_ok(
        $log_re,
        "the $name should be logged as expected",
    );
}

subtest 'simple timer' => sub {
    assert_log {
        my $t = timer('test1');
        usleep 1000;
    } qr/\Aduration\(0\.\d{4}\) test1\z/;
};

subtest 'nested timers' => sub {
    assert_log {
        my $t1 = timer('outer');

        assert_log {
            my $t2 = timer('inner');
            usleep 2000;
        } qr/\Aduration\(0\.\d{4}\) {5}inner\z/, 'inner event';

        usleep 1000;
    } qr/\Aduration\(0\.\d{4}\) outer\z/, 'outer event';
};

subtest 'all options' => sub {
    assert_log {
        my $t = timer('test1', {
            prefix => '-pre-',
            context => '-con-',
        } );
        usleep 3000;
    } qr/\A-pre-duration\(0\.\d{4}\) -con-: test1\z/;
};

sub mysub {
    my $x = subroutine_timer();
    usleep 1000;
}

subtest 'subroutine_timer' => sub {
    assert_log { mysub }
        qr/\Aduration\(0\.\d{4}\) main->mysub\z/;
};

subtest 'summary' => sub {
    Log::Any::Adapter::Test->clear;
    Log::Timer::report_timing_stats();

    my @sorted_messages = sort { $a->{timer} cmp $b->{timer} }
        map { +{
            category => $_->{category},
            level    => $_->{level},
            timer    => ($_->{message} =~ m{\bfor \((.+?)\)}),
            count    => ($_->{message} =~ m{\bcount\((.+?)\)}),
        } } @{ Log::Any::Adapter::Test->msgs };

    explain(Log::Any::Adapter::Test->msgs);

    cmp_deeply(
        \@sorted_messages,
        all(
            array_each({
                category => "Log::Timer",
                level    => "info",
                timer    => ignore(),
                count    => ignore(),
            }),
            [
                superhashof({ count => 1, timer => 'inner' }),
                superhashof({ count => 1, timer => 'main->mysub' }),
                superhashof({ count => 1, timer => 'outer' }),
                superhashof({ count => 2, timer => 'test1' }),
            ],
        ),
        'the summary should be logged',
    );
};

done_testing;
