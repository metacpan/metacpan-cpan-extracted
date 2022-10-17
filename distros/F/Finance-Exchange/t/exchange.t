#!/usr/bin/perl

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings;

use Finance::Exchange;

my @exchanges = (
    'ICE_LIFFE',    'EEI_PA',      'BIS',         'NYSE_SPC',        'EGX',         'KRX',    'SYNFSE',  'BSE',
    'HKF',          'BOVESPA',     'SWX',         'TRSE',            'EURONEXT',    'SYNTSE', 'RANDOM',  'TSE_S',
    'TSE',          'OSLO',        'LSE',         'SES',             'SYNLSE',      'EEI_BU', 'SFE',     'SAS',
    'EUREX',        'SYNNYSE_SPC', 'ISE',         'NSE',             'KSE',         'STOXX',  'SGX',     'EEI_AM',
    'BI',           'FSE',         'MEFF',        'ASX_S',           'SYNEURONEXT', 'NYSE',   'MOF',     'BMF',
    'NASDAQ_INDEX', 'EEI_LI',      'CME',         'ASX',             'OMX',         'FOREX',  'DFM',     'ADS',
    'SYNSTOXX',     'SZSE',        'SYNSWX',      'RTS',             'JSC',         'METAL',  'OSE',     'FS',
    'NZSE',         'ODLS',        'SP_GLOBAL',   'JSE',             'NASDAQ',      'BM',     'HKSE',    'MICEX',
    'SYNNYSE_DJI',  'SP_GSCI',     'EUREX_SWISS', 'RANDOM_NOCTURNE', 'IDM',         'SSE',    'OIL_OTC', 'BRENT_OTC'
);
subtest 'exchange object construction' => sub {
    foreach my $exchange_symbol (@exchanges) {
        lives_ok { Finance::Exchange->create_exchange('ASX') } 'can create an exchange object for ' . $exchange_symbol;
    }
    throws_ok { Finance::Exchange->create_exchange('unknown') } qr/Config for exchange\[unknown\] not specified in exchange.yml/,
        'throws error if exchange symbol is unknown';
};

subtest 'trading_days' => sub {
    my $expected = {
        everyday     => ['RANDOM', 'RANDOM_NOCTURNE'],
        sun_thru_thu => ['EGX',    'SAS', 'KRX', 'DFM', 'ADS'],
        weekdays     => [
            'ICE_LIFFE',   'EEI_PA', 'BIS',         'NYSE_SPC', 'KRX',          'SYNFSE', 'BSE',         'HKF',
            'BOVESPA',     'SWX',    'TRSE',        'EURONEXT', 'SYNTSE',       'TSE_S',  'TSE',         'OSLO',
            'LSE',         'SES',    'SYNLSE',      'EEI_BU',   'SFE',          'EUREX',  'SYNNYSE_SPC', 'ISE',
            'NSE',         'STOXX',  'SGX',         'EEI_AM',   'BI',           'FSE',    'MEFF',        'ASX_S',
            'SYNEURONEXT', 'NYSE',   'MOF',         'BMF',      'NASDAQ_INDEX', 'EEI_LI', 'CME',         'ASX',
            'OMX',         'FOREX',  'SYNSTOXX',    'SZSE',     'SYNSWX',       'RTS',    'JSC',         'METAL',
            'OSE',         'FS',     'NZSE',        'ODLS',     'SP_GLOBAL',    'JSE',    'NASDAQ',      'BM',
            'HKSE',        'MICEX',  'SYNNYSE_DJI', 'SP_GSCI',  'EUREX_SWISS',  'IDM',    'SSE',         'OIL_OTC',
            'BRENT_OTC'
        ],
    };

    foreach my $ex (map { Finance::Exchange->create_exchange($_) } @exchanges) {
        unless ($expected->{$ex->trading_days}) {
            fail('unknown trading days ' . $ex->trading_days);
        } else {
            if (grep { $ex->symbol eq $_ } @{$expected->{$ex->trading_days}}) {
                pass('trading_days matched for ' . $ex->symbol);
            } else {
                fail('Wrong trading_days found for ' . $ex->symbol);
            }
        }
    }
};

subtest 'exchange currency' => sub {
    my $expected = {
        'AED' => ['DFM',     'ADS'],
        'AUD' => ['SFE',     'ASX_S', 'ASX'],
        'BRL' => ['BOVESPA', 'BMF'],
        'CAD' => ['TRSE'],
        'CHF' => ['SWX',  'SYNSWX', 'EUREX_SWISS'],
        'CNY' => ['SZSE', 'SSE'],
        'EGP' => ['EGX'],
        'EUR' => [
            'EEI_PA', 'SYNFSE', 'EURONEXT', 'EEI_BU',      'EUREX',  'ISE',      'STOXX', 'EEI_AM',
            'BI',     'FSE',    'MEFF',     'SYNEURONEXT', 'EEI_LI', 'SYNSTOXX', 'BM',    'IDM'
        ],
        'GBP' => ['ICE_LIFFE', 'LSE', 'SYNLSE', 'FS'],
        'HKD' => ['HKF', 'HKSE'],
        'IDR' => ['JSC'],
        'INR' => ['BSE',    'NSE'],
        'JPY' => ['SYNTSE', 'TSE_S', 'TSE', 'OSE'],
        'KRW' => ['KRX'],
        'KWD' => ['KRX'],
        'NOK' => ['OSLO'],
        'NZD' => ['NZSE'],
        'RUB' => ['MICEX'],
        'SAR' => ['SAS'],
        'SEK' => ['OMX'],
        'SGD' => ['SES', 'SGX'],
        'TRY' => ['BIS'],
        'USD' => [
            'NYSE_SPC',  'SYNNYSE_SPC', 'NYSE',        'MOF',     'NASDAQ_INDEX', 'CME', 'RTS', 'ODLS',
            'SP_GLOBAL', 'NASDAQ',      'SYNNYSE_DJI', 'SP_GSCI', 'OIL_OTC',      'BRENT_OTC'
        ],
        'ZAR' => ['JSE'],
    };
    my %undef_currency_exchanges = (
        RANDOM          => 1,
        FOREX           => 1,
        METAL           => 1,
        RANDOM_NOCTURNE => 1
    );

    foreach my $ex (map { Finance::Exchange->create_exchange($_) } @exchanges) {
        if (not $ex->currency and exists $undef_currency_exchanges{$ex->symbol}) {
            pass('Currency is undefined for ' . $ex->symbol);
        } elsif (grep { $ex->symbol eq $_ } @{$expected->{$ex->currency}}) {
            pass('currency matched for ' . $ex->symbol);
        } else {
            fail('Wrong currency found for ' . $ex->symbol);
        }
    }
};

subtest 'market_times' => sub {
    my $expected = {
        'ASX' => {
            dst => {
                daily_close      => 5 * 3600,
                daily_open       => -1 * 3600,
                daily_settlement => 8 * 3600,
            },
            partial_trading => {
                dst_close      => 3 * 3600 + 10 * 60,
                dst_open       => -1 * 3600,
                standard_close => 4 * 3600 + 10 * 60,
                standard_open  => 0,
            },
            standard => {
                daily_close      => 6 * 3600,
                daily_open       => 0,
                daily_settlement => 9 * 3600,
            },
        },
        'ASX_OTC' => {
            dst => {
                daily_close      => 19 * 3600,
                daily_open       => 0 * 3600,
                daily_settlement => 21 * 3600,
                trading_breaks   => [5 * 3600 + 30 * 60, 6 * 3600 + 30 * 60],
            },
            standard => {
                daily_close      => 20 * 3600,
                daily_open       => 0 * 3600,
                daily_settlement => 22 * 3600,
                trading_breaks   => [6 * 3600 + 30 * 60, 7 * 3600 + 30 * 60],
            },
        },

    };

    foreach my $exchange (keys %{$expected}) {
        my $asx = Finance::Exchange->create_exchange($exchange);
        foreach my $key (keys %{$asx->market_times}) {
            foreach my $key2 (keys %{$asx->market_times->{$key}}) {
                if ($key2 eq 'trading_breaks') {
                    is $asx->market_times->{$key}->{$key2}[0][0]->seconds, $expected->{$exchange}->{$key}->{$key2}[0], 'trading breaks matches';
                    is $asx->market_times->{$key}->{$key2}[0][1]->seconds, $expected->{$exchange}->{$key}->{$key2}[1], 'trading breaks matches';

                } else {
                    is $asx->market_times->{$key}->{$key2}->seconds, $expected->{$exchange}->{$key}->{$key2}, 'market times matches';
                }
            }
        }
    }
};

subtest 'exchange object caching' => sub {
    my $obj1 = Finance::Exchange->create_exchange('ASX');
    my $obj2 = Finance::Exchange->create_exchange('ASX');
    my $obj3 = Finance::Exchange->create_exchange('FOREX');

    is $obj1,   $obj2, 'cached';
    isnt $obj1, $obj3, 'returns a different object for FOREX';
};

done_testing();
