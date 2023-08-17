#!/usr/bin/perl

use strict;
use warnings;

use Test::MockTime qw( :all );
use Test::Most;
use Test::FailWarnings;
use Time::Local ();

use Finance::Exchange;
use Finance::Calendar;

my $date = Date::Utility->new('2013-12-01');    # first of December 2014

my $calendar = {
    holidays => {
        1367798400 => {
            "Early May Bank Holiday" => [qw(LSE)],
        },
        1387929600 => {
            "Christmas Day" => [qw(LSE FOREX METAL)],
        },
        1388534400 => {
            "New Year's Day" => [qw(LSE FOREX METAL)],
        },
        1364774400 => {
            "Easter Monday" => [qw(LSE USD)],
        },
    },
    early_closes => {
        1261612800 => {
            '4h30m' => ['HKSE'],
        },
        1293148800 => {'12h30m' => ['LSE']},
        1387843200 => {
            '12h30m' => ['LSE'],
        },
        1482364800 => {
            '18h' => ['FOREX', 'METAL'],
        },
    },
    late_opens => {
        1293148800 => {
            '2h30m' => ['HKSE'],
        },
    },
};

my $tc = Finance::Calendar->new(calendar => $calendar);
my ($LSE, $RANDOM, $FOREX, $ASX, $HKSE, $METAL, $JSC, $SWX) =
    map { Finance::Exchange->create_exchange($_) } qw(LSE RANDOM FOREX ASX HKSE METAL JSC SWX);

subtest 'trades_on' => sub {
    ok !$tc->trades_on($LSE,   Date::Utility->new('1-Jan-14')),  'LSE doesn\'t trade on 1-Jan-14 because it is on holiday.';
    ok !$tc->trades_on($LSE,   Date::Utility->new('12-May-13')), 'LSE doesn\'t trade on weekend (12-May-13).';
    ok $tc->trades_on($LSE,    Date::Utility->new('3-May-13')),  'LSE trades on normal day 4-May-13.';
    ok !$tc->trades_on($LSE,   Date::Utility->new('5-May-13')),  'LSE doesn\'t trade on 5-May-13 as it is a weekend.';
    ok $tc->trades_on($RANDOM, Date::Utility->new('5-May-13')),  'RANDOM trades on 5-May-13 as it is open on weekends.';
};

subtest 'trade_date_after' => sub {
    # forex holidays are on 2013-12-25 and 2014-01-01
    is $tc->trade_date_after($FOREX, Date::Utility->new('2013-12-23'))->date, '2013-12-24', 'trade date is next day if it is not a holiday';
    is $tc->trade_date_after($FOREX, Date::Utility->new('2013-12-24'))->date, '2013-12-26', 'trade date is on 26-Dec because 25-Dec is a holiday';
    is $tc->trade_date_after($FOREX, Date::Utility->new('2013-12-27'))->date, '2013-12-30',
        'trade date is on 30-Dec because Forex does not trade on weekend';

    is $tc->trade_date_after($RANDOM, Date::Utility->new('2013-12-24'))->date, '2013-12-25', 'trade date is on 25-Dec';
    is $tc->trade_date_after($RANDOM, Date::Utility->new('2013-12-27'))->date, '2013-12-28',
        'trade date is on 30-Dec because Random indices open on weekend';
};

subtest 'trade_date_before' => sub {
    # forex holidays are on 2013-12-25 and 2014-01-01
    is $tc->trade_date_before($FOREX, Date::Utility->new('2013-12-24'))->date, '2013-12-23', 'trade date is previous day if it is not a holiday';
    is $tc->trade_date_before($FOREX, Date::Utility->new('2013-12-26'))->date, '2013-12-24', 'trade date is on 24-Dec because 25-Dec is a holiday';
    is $tc->trade_date_before($FOREX, Date::Utility->new('2013-12-30'))->date, '2013-12-27',
        'trade date is on 27-Dec because Forex does not trade on weekend';

    is $tc->trade_date_before($RANDOM, Date::Utility->new('2013-12-25'))->date, '2013-12-24', 'trade date is on 24-Dec';
    is $tc->trade_date_before($RANDOM, Date::Utility->new('2013-12-28'))->date, '2013-12-27',
        'trade date is on 27-Dec because Random indices open on weekend';
};

subtest 'trading_date_for' => sub {
    my $non_dst_asx = Date::Utility->new('2017-09-30 15:59:59');
    my $dst_asx     = Date::Utility->new('2017-09-30 16:00:00');
    ok !$tc->is_in_dst_at($ASX, $non_dst_asx->epoch);
    ok $tc->is_in_dst_at($ASX,  $dst_asx->epoch);
    is $tc->trading_date_for($ASX, $non_dst_asx)->epoch, $non_dst_asx->truncate_to_day->epoch, 'same day on non dst';
    is $tc->trading_date_for($ASX, $dst_asx)->epoch,     $dst_asx->truncate_to_day->epoch,     'same day if time is before open on dst';
    is $tc->trading_date_for($ASX, $dst_asx->plus_time_interval('7h'))->epoch, $dst_asx->plus_time_interval('1d')->truncate_to_day->epoch, 'next day';
};

subtest 'calendar_days_to_trade_date_after' => sub {
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('20-Dec-13')),
        3, '3 calendar days until next trading day on FOREX after 20-Dec-13');
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('27-Dec-13')),
        3, '3 calendar days until next trading day on FOREX after 27-Dec-13');
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('7-Mar-13')),
        1, '1 calendar day until next trading day on FOREX after 7-Mar-13');
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('8-Mar-13')),
        3, '3 calendar days until next trading day on FOREX after 8-Mar-13');
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('9-Mar-13')),
        2, '2 calendar days until next trading day on FOREX after 9-Mar-13');
    is($tc->calendar_days_to_trade_date_after($FOREX, Date::Utility->new('10-Mar-13')),
        1, '1 calendar day until next trading day on FOREX after 10-Mar-13');
};

subtest 'trading_days_between' => sub {
    is($tc->trading_days_between($LSE, Date::Utility->new('29-Mar-13'), Date::Utility->new('1-Apr-13')),
        0, 'No trading days between 29th Mar and 1st Apr on LSE');
    is($tc->trading_days_between($LSE, Date::Utility->new('11-May-13'), Date::Utility->new('12-May-13')),
        0, 'No trading days between 11th and 12th May on LSE (over weekend)');
    is($tc->trading_days_between($LSE, Date::Utility->new('4-May-13'), Date::Utility->new('6-May-13')),
        0, 'No trading days between 4th May and 6th May on LSE (over weekend, then holiday on Monday)');
    is($tc->trading_days_between($LSE, Date::Utility->new('10-May-13'), Date::Utility->new('14-May-13')),
        1, '1 trading day between 10th and 14th May on LSE (over weekend, Monday open)');
};

subtest 'holiday_days_between' => sub {
    is $tc->holiday_days_between($LSE, Date::Utility->new('24-Dec-13'),  Date::Utility->new('3-Jan-14')), 2, "two holidays over the year end on LSE.";
    is $tc->holiday_days_between($LSE, Date::Utility->new('2017-03-03'), Date::Utility->new('2017-03-06')), 0, 'no holidays over the weekend';
};

subtest 'open/close' => sub {
    # testing the "use current time" methods for one date/time only.
    # Rest of tests will use the "_at" methods ("current time" ones
    # use them anyway).
    Test::MockTime::set_fixed_time('2013-05-03T09:00:00Z');
    is($tc->is_open($LSE), 1, 'LSE is open at 9am on a trading day');
    Test::MockTime::restore_time();

    # before opening time on an LSE trading day:
    my $six_am       = Date::Utility->new('3-May-13 06:00:00');
    my $six_am_epoch = $six_am->epoch;
    is($tc->is_open_at($LSE, $six_am),             undef, 'LSE not open at 6am');
    is($tc->seconds_since_open_at($LSE, $six_am),  undef, 'at 6am, LSE not open yet');
    is($tc->seconds_since_close_at($LSE, $six_am), undef, 'at 6am, LSE hasn\'t closed yet');

    # after closing time on an LSE trading day:
    my $six_pm = Date::Utility->new('3-May-13 18:00:00');
    is($tc->is_open_at($LSE, $six_pm),             undef,         'LSE not open at 6pm.');
    is($tc->seconds_since_open_at($LSE, $six_pm),  11 * 60 * 60,  'at 6pm, LSE opening was 11 hours ago.');
    is($tc->seconds_since_close_at($LSE, $six_pm), 2.5 * 60 * 60, 'at 6pm, LSE has been closed for 2.5 hours.');

    # LSE holiday:
    my $tc_holiday = Date::Utility->new('6-May-13 12:00:00');
    is($tc->is_open_at($LSE, $tc_holiday),             undef, 'is_open_at LSE not open today at all.');
    is($tc->seconds_since_open_at($LSE, $tc_holiday),  undef, 'seconds_since_open_at LSE not open today at all.');
    is($tc->seconds_since_close_at($LSE, $tc_holiday), undef, 'seconds_since_close_at LSE not open today at all.');
    # DST stuff
    # Europe: last Sunday of March.
    is($tc->is_open_at($LSE, Date::Utility->new('29-Mar-13 07:30:00')), undef, 'LSE not open at 7:30am GMT during winter.');
    is($tc->is_open_at($LSE, Date::Utility->new('3-Apr-13 07:30:00')),  1,     'LSE open at 7:30am GMT during summer.');

    is(
        $tc->opening_on($LSE, Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 07:00')->epoch,
        'Opening time of LSE on 3-May-13 is 07:00.'
    );
    is(
        $tc->closing_on($LSE, Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 15:30')->epoch,
        'Closing time of LSE on 3-May-13 is 14:30.'
    );
    is(
        $tc->opening_on($LSE, Date::Utility->new('8-Feb-13'))->epoch,
        Date::Utility->new('8-Feb-13 08:00')->epoch,
        'Opening time of LSE on 8-Feb-13 is 08:00 (winter time).'
    );
    is(
        $tc->closing_on($LSE, Date::Utility->new('8-Feb-13'))->epoch,
        Date::Utility->new('8-Feb-13 16:30')->epoch,
        'Closing time of LSE on 8-Feb-13 is 16:30 (winter time).'
    );
    is($tc->opening_on($LSE, Date::Utility->new('12-May-13')), undef, 'LSE doesn\'t open on weekend (12-May-13).');
    ok(!$tc->closes_early_on($LSE, Date::Utility->new('23-Dec-13')), 'LSE doesn\'t close early on 23-Dec-10');
    ok($tc->closes_early_on($LSE,  Date::Utility->new('24-Dec-13')), 'LSE closes early on 24-Dec-10');
    is(
        $tc->closing_on($LSE, Date::Utility->new('24-Dec-13'))->epoch,
        Date::Utility->new('24-Dec-13 12:30')->epoch,
        '(Early) closing time of LSE on 24-Dec-13 is 12:30.'
    );

    # Two session trading stuff:
    my $lunchbreak_epoch = Date::Utility->new('3-May-13 04:30:00');
    is($tc->is_open_at($HKSE, $lunchbreak_epoch), undef, 'HKSE closed for lunch!');
    is($tc->seconds_since_open_at($HKSE, $lunchbreak_epoch),
        undef, 'seconds since open is undef if market is closed (which includes closed for lunch).');
    is($tc->seconds_since_close_at($HKSE, $lunchbreak_epoch), 31 * 60, '1 hour into lunch, HKSE closed 31 minutes ago.');

    my $tc_close_epoch = Date::Utility->new('3-May-13 07:40:00');
    is($tc->seconds_since_close_at($HKSE, $tc_close_epoch), 0, 'HKSE: seconds since close at close should be zero (as opposed to undef).');
    ok(!$tc->opens_late_on($HKSE, Date::Utility->new('23-Dec-13')), 'HKSE doesn\'t open late on 23-Dec-10');
    ok($tc->opens_late_on($HKSE,  Date::Utility->new('24-Dec-10')), 'HKSE opens late on 24-Dec-10');
    is(
        $tc->opening_on($HKSE, Date::Utility->new('24-Dec-10'))->epoch,
        Date::Utility->new('24-Dec-10 02:30')->epoch,
        '(Late) opening time of HKSE on 24-Dec-10 is 02:30.'
    );

    is($tc->closing_on($HKSE, Date::Utility->new('23-Dec-13'))->time_hhmm, '07:40', 'Closing time of HKSE on 23-Dec-10 is 07:40.');
    is(
        $tc->opening_on($HKSE, Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 01:30')->epoch,
        '[epoch test] Opening time of HKSE on 3-May-13 is 01:30.'
    );
    ok($tc->trading_breaks($HKSE, Date::Utility->new('3-May-13')), 'HKSE has trading breaks');
    is $tc->trading_breaks($HKSE, Date::Utility->new('3-May-13'))->[0]->[0]->epoch, Date::Utility->new('3-May-13 03:59')->epoch,
        'correct interval open time';
    is $tc->trading_breaks($HKSE, Date::Utility->new('3-May-13'))->[0]->[1]->epoch, Date::Utility->new('3-May-13 05:00')->epoch,
        'correct interval close time';
    is(
        $tc->closing_on($HKSE, Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 07:40')->epoch,
        '[epoch test] Closing time of HKSE on 3:-May-13 is 07:40.'
    );

    is($tc->is_open_at($ASX, Date::Utility->new('5-Apr-13 05:30:00')), undef, 'ASX not open at 5:30am GMT during Aussie "summer".');
    is($tc->is_open_at($ASX, Date::Utility->new('8-Apr-13 23:30:00')), undef, 'ASX not open at 23:30 GMT a day earlier during Aussie "winter".');
    is($tc->is_open_at($ASX, Date::Utility->new('8-Apr-13 05:30:00')), 1,     'ASX open at 5:30am GMT during Aussie "winter".');

    # Checking for exact open date for opening of markets that have breaks during the day
    my $hkse_open_date = Date::Utility->new('2020-10-13 01:30:00');
    is($tc->seconds_since_open_at($HKSE, $hkse_open_date),
        0, 'seconds_since open for markets that have breaks during the day should return 0 at market open');
};

subtest 'seconds_of_trading_between' => sub {
    my $HKSE_TRADE_DURATION_DAY     = ((2 * 3600 + 29 * 60) + (2 * 3600 + 40 * 60));
    my $HKSE_TRADE_DURATION_MORNING = 2 * 3600 + 29 * 60;
    my $HKSE_TRADE_DURATION_EVENING = 2 * 3600 + 40 * 60;

    # HSI Opens 02:00 hours, closes 04:30 for lunch, reopens at 06:30 after lunch, and closes for the day at 08:00.
    # Thus, opens for 2.5 hours first session, and 1.5 hours the second session for a total of 4 hours per day.
    my @test_data = (
        # Tuesday 10 March 2009 00:00, up to end of the day
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 86400),
            trading_time => $HKSE_TRADE_DURATION_DAY,
            desc         => 'Trade time : Full Day'
        },
        # Tuesday 10 March 2009 00:00, up to start of lunch break
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + (3 * 3600 + 59 * 60)),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time : Lunch Break',
        },
        # Tuesday 10 March 2009 00:00, up to end of lunch break
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 5 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade Time : End of lunch Break',
        },
        # Tuesday 10 March 2009 02:30, up to end of lunch break
        {
            start        => Date::Utility->new(1236643200 + 1.5 * 3600),
            end          => Date::Utility->new(1236643200 + 5 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time : Start of trade day to End lunch Break',
        },
        # Tuesday 10 March 2009 00:00, up to 07:00
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 7 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 00:00 GMT to 07:00 GMT'
        },
        # Tuesday 10 March 2009 00:00, up to Weds 07:00
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 86400 + 7 * 3600),
            trading_time => $HKSE_TRADE_DURATION_DAY + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 00:00 GMT to next day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Weds 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to next day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Thursday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 2 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + $HKSE_TRADE_DURATION_DAY + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to alternate day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Friday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 3 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (2 * $HKSE_TRADE_DURATION_DAY) + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to third day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:00, up to Saturday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 4 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY),
            desc         => 'Trade time : From 03:00 GMT to weekend day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:00, up to Sunday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 5 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY),
            desc         => 'Trade time : From 03:00 GMT to weekend(sunday) day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to next Monday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 6 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY) + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to sixth(monday) day 07:00 GMT'
        },
        # EARLY CLOSE TESTS
        # Thursday 24 December 2009. Market closes early at 04:30.
        {
            start        => Date::Utility->new('24-Dec-09 01:00:00'),
            end          => Date::Utility->new('24-Dec-09 03:00:00'),
            trading_time => (1 * 3600) + (30 * 60),
            desc         => 'Trade time Early Close : Before close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:00:00'),
            end          => Date::Utility->new('24-Dec-09 09:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 05:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to After Close 2',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 04:30:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to At Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 04:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to Before Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 04:30:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : Close of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 05:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 06:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close 2',
        },
        {
            start        => Date::Utility->new('24-Dec-09 07:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close 3',
        },
    );
    TEST:
    foreach my $data (@test_data) {
        my $dt                    = $data->{'start'};
        my $dt_end                = $data->{'end'};
        my $expected_trading_time = $data->{'trading_time'};
        my $desc                  = $data->{'desc'};
        is(
            $tc->seconds_of_trading_between_epochs($HKSE, $dt, $dt_end),
            $expected_trading_time,
            'testing "seconds_of_trading_between_epochs(' . $dt->epoch . ', ' . $dt_end->epoch . ')" on HKSE : [' . $desc . ']',
        );
    }
};

subtest 'regular_trading_day_after' => sub {
    my $weekend     = Date::Utility->new('2014-03-29');
    my $regular_day = $tc->regular_trading_day_after($FOREX, $weekend);
    is($regular_day->date_yyyymmdd, '2014-03-31', 'correct regular trading day after weekend');
    my $new_year = Date::Utility->new('2014-01-01');
    $regular_day = $tc->regular_trading_day_after($FOREX, $new_year);
    is($regular_day->date_yyyymmdd, '2014-01-02', 'correct regular trading day after New Year');
};

subtest 'trading_period' => sub {
    my $trading_date = Date::Utility->new('15-Jul-2015');
    my $p            = $tc->trading_period($HKSE, $trading_date);
    # daily_open       => '1h30m',
    # trading_breaks   => [['3h59m', '5h00m']],
    # daily_close      => '7h40m',
    my $expected = [{
            open  => Time::Local::timegm(0, 30, 1, 15, 6, 115),
            close => Time::Local::timegm(0, 59, 3, 15, 6, 115)
        },
        {
            open  => Time::Local::timegm(0, 0,  5, 15, 6, 115),
            close => Time::Local::timegm(0, 40, 7, 15, 6, 115)
        },
    ];
    is_deeply $p, $expected, 'two periods for HKSE';

    $p = $tc->trading_period($FOREX, $trading_date);
    # daily_open: 0s
    # daily_close: 23h59m59s
    $expected = [{
            open  => Time::Local::timegm(0,  0,  0,  15, 6, 115),
            close => Time::Local::timegm(59, 59, 23, 15, 6, 115)
        },
    ];
    is_deeply $p, $expected, 'one period for FOREX';
};

subtest 'is_holiday_for' => sub {
    my $expected_LSE_holidays = {
        "6-May-2013"  => "Early May Bank Holiday",
        "25-Dec-2013" => "Christmas Day",
        "1-Jan-2014"  => "New Year's Day",
        "1-Apr-2013"  => "Easter Monday",
    };

    foreach my $date_str (keys %$expected_LSE_holidays) {
        is $tc->is_holiday_for('LSE', Date::Utility->new($date_str)), $expected_LSE_holidays->{$date_str}, 'holiday matches';
    }

    # tuesday non-holiday
    ok !$tc->is_holiday_for('LSE',   Date::Utility->new('2013-04-02')), 'not a holiday on a non-holiday weekday';
    ok !$tc->is_holiday_for('LSE',   Date::Utility->new('2013-12-26')), 'not a holiday on a pseudo-holiday';
    ok !$tc->is_holiday_for('FOREX', Date::Utility->new('2013-05-06')), 'not a holiday on a non-holiday weekday';

    ok !$tc->is_holiday_for('USD', Date::Utility->new('2013-04-02')), 'not a US holiday on 2-Apr';
    ok $tc->is_holiday_for('USD',  Date::Utility->new('2013-04-01')), 'a US holiday on 1-Apr';
};

subtest 'regularly_adjusts_trading_hours_on' => sub {
    my $monday = Date::Utility->new('2013-08-26');
    my $friday = $monday->plus_time_interval('4d');

    note 'It is expected that this long-standing close in forex will not change, so we can use it to verify the implementation.';
    ok(!$tc->regularly_adjusts_trading_hours_on($FOREX, $monday), 'FOREX does not regularly adjust trading hours on ' . $monday->day_as_string);

    my $friday_changes = $tc->regularly_adjusts_trading_hours_on($FOREX, $friday);
    ok($friday_changes,                       'FOREX regularly adjusts trading hours on ' . $friday->day_as_string);
    ok(exists $friday_changes->{daily_close}, ' changing daily_close');
    is($friday_changes->{daily_close}->{to},   '20h55m',  '  to 20h55m after midnight');
    is($friday_changes->{daily_close}->{rule}, 'Fridays', '  by rule "Friday"');

    ok(!$tc->regularly_adjusts_trading_hours_on($METAL, $monday), 'METAL does not regularly adjust trading hours on ' . $monday->day_as_string);
    my $metal_friday = $tc->regularly_adjusts_trading_hours_on($METAL, $friday);
    ok($metal_friday,                       'METAL regularly adjusts trading hours on ' . $friday->day_as_string);
    ok(exists $metal_friday->{daily_close}, ' changing daily_close');
    is($metal_friday->{daily_close}->{to},   '20h55m',  '  to 20h55m after midnight');
    is($metal_friday->{daily_close}->{rule}, 'Fridays', '  by rule "Friday"');

};

# Test regularly_adjust_trading_hours_on through closes_early_on
subtest 'regularly_adjust_trading_hours_on_2' => sub {
    my $monday = Date::Utility->new('2013-08-26');
    my $friday = $monday->plus_time_interval('4d');

    ok($tc->closes_early_on($FOREX, $friday), 'Forex closes early on ' . $friday->day_as_string);
    ok($tc->closes_early_on($METAL, $friday), 'Metal closes early on ' . $friday->day_as_string);
};

# Test next_open_at for cases - when exchange will open on next day, exchange is in between trading brakes,
# exchange will open on the same day
subtest 'next_open_at' => sub {
    # SWX - it has no trading break
    # Weekday - Exchange is already closed, should be open on next day
    my $monday_closed     = Date::Utility->new('12-Jun-23 19:00:00');
    my $next_trading_time = $tc->next_open_at($SWX, $monday_closed);
    is($next_trading_time->datetime, '2023-06-13 07:00:00', 'Correct next open date and time.');

    # Weekday - Exchange is not open yet 01 am GMT and it is a weekday, should be open on at 07 GMT same day
    my $early_monday = Date::Utility->new('12-Jun-23 01:00:00');
    $next_trading_time = $tc->next_open_at($SWX, $early_monday);
    is($next_trading_time->datetime, '2023-06-12 07:00:00', 'Correct next open date and time.');

    # Weekend - Exchange is already closed and it is a weekend, should be open on next monday
    my $last_weekday = $monday_closed->plus_time_interval('4d');
    $next_trading_time = $tc->next_open_at($SWX, $last_weekday);
    is($next_trading_time->datetime, '2023-06-19 07:00:00', 'Correct next open date and time.');

    # HKSE - it has trading breaks
    # Weekday - Exchange is already closed, should be open on next day
    my $hkse_monday_closed = Date::Utility->new('12-Jun-23 08:00:00');
    $next_trading_time = $tc->next_open_at($HKSE, $hkse_monday_closed);
    is($next_trading_time->datetime, '2023-06-13 01:30:00', 'Correct next open date and time.');

    # Weekday - Exchange is not open yet 01 am GMT and it is a weekday, should be open on at 01:30 GMT same day
    my $hkse_early_monday = Date::Utility->new('12-Jun-23 01:00:00');
    $next_trading_time = $tc->next_open_at($HKSE, $hkse_early_monday);
    is($next_trading_time->datetime, '2023-06-12 01:30:00', 'Correct next open date and time.');

    # Weekday - Exchange is in trading brake
    my $hkse_in_break = Date::Utility->new('12-Jun-23 04:15:00');
    $next_trading_time = $tc->next_open_at($HKSE, $hkse_in_break);
    is($next_trading_time->datetime, '2023-06-12 05:00:00', 'Correct next open date and time.');

    # Weekend - Exchange is already closed and it is a weekend, should be open on next monday
    my $hkse_last_weekday = $hkse_monday_closed->plus_time_interval('4d');
    $next_trading_time = $tc->next_open_at($HKSE, $hkse_last_weekday);
    is($next_trading_time->datetime, '2023-06-19 01:30:00', 'Correct next open date and time.');

};

done_testing();
