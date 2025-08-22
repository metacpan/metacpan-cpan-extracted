#!/usr/bin/perl

use Test::Deep;
use Test::Exception;
use Test::FailWarnings;
use Test::Most;

use File::ShareDir;
use Finance::Exchange;
use YAML::XS qw(LoadFile);

my $exchange_config = YAML::XS::LoadFile(File::ShareDir::dist_file('Finance-Exchange', 'exchange.yml'));
my @exchanges       = sort keys %$exchange_config;

subtest 'exchange object construction' => sub {
    foreach my $exchange_symbol (@exchanges) {
        lives_ok { Finance::Exchange->create_exchange($exchange_symbol) } 'can create an exchange object for ' . $exchange_symbol;
    }
    throws_ok { Finance::Exchange->create_exchange('unknown') } qr/Config for exchange\[unknown\] not specified in exchange.yml/,
        'throws error if exchange symbol is unknown';
};

subtest 'trading_days' => sub {
    my $expected = {
        everyday     => ['RANDOM',           'RANDOM_NOCTURNE', 'CRYPTOCURRENCY', 'RSI_CRYPTO'],
        sun_thru_thu => ['EGX',              'SAS', 'DFM', 'ADS', 'KSE'],
        sun_thru_fri => ['RSI_FOREX_EURUSD', 'RSI_FOREX_GBPUSD', 'RSI_FOREX_USDJPY', 'RSI_METAL'],
        weekdays     => [
            'ICE_LIFFE',   'EEI_PA',   'BIS',         'NYSE_SPC',   'KRX',          'SYNFSE',       'BSE',          'HKF',
            'BOVESPA',     'SWX',      'TRSE',        'EURONEXT',   'SYNTSE',       'TSE_S',        'TSE',          'OSLO',
            'LSE',         'SES',      'SYNLSE',      'EEI_BU',     'SFE',          'EUREX',        'SYNNYSE_SPC',  'ISE',
            'NSE',         'STOXX',    'SGX',         'EEI_AM',     'BI',           'FSE',          'MEFF',         'ASX_S',
            'SYNEURONEXT', 'NYSE',     'MOF',         'BMF',        'NASDAQ_INDEX', 'EEI_LI',       'CME',          'ASX',
            'OMX',         'FOREX',    'SYNSTOXX',    'SZSE',       'SYNSWX',       'RTS',          'JSC',          'METAL',
            'OSE',         'FS',       'NZSE',        'ODLS',       'SP_GLOBAL',    'JSE',          'NASDAQ',       'BM',
            'HKSE',        'MICEX',    'SYNNYSE_DJI', 'SP_GSCI',    'EUREX_SWISS',  'IDM',          'SSE',          'OIL_OTC',
            'BRENT_OTC',   'CME_OTC',  'SGX_OTC',     'ASX_OTC',    'BM_OTC',       'EURONEXT_OTC', 'FSE_OTC',      'HKSE_OTC',
            'ICE',         'JSE_OTC',  'LSE_OTC',     'NASDAQ_OTC', 'NSE_OTC',      'NYSE_OTC',     'NYSE_SPC_OTC', 'STOXX_OTC',
            'SWX_OTC',     'TRSE_OTC', 'TSE_OTC'
        ],
    };

    foreach my $ex (map { Finance::Exchange->create_exchange($_) } @exchanges) {
        unless ($expected->{$ex->trading_days}) {
            fail('unknown trading days ' . $ex->trading_days);
        } else {
            if (grep { $ex->symbol eq $_ } @{$expected->{$ex->trading_days}}) {
                pass('trading_days matched for ' . $ex->symbol);
            } else {
                fail('Wrong trading_days found for ' . $ex->symbol . ' should be ' . $ex->trading_days);
            }
        }
    }
};

subtest 'exchange currency' => sub {
    my $expected = {
        'AED' => ['DFM',     'ADS'],
        'AUD' => ['SFE',     'ASX_S', 'ASX', 'ASX_OTC'],
        'BRL' => ['BOVESPA', 'BMF'],
        'CAD' => ['TRSE',    'TRSE_OTC'],
        'CHF' => ['SWX',     'SYNSWX', 'EUREX_SWISS', 'SWX_OTC'],
        'CNY' => ['SZSE',    'SSE'],
        'EGP' => ['EGX'],
        'EUR' => [
            'EEI_PA', 'SYNFSE',       'EURONEXT', 'EEI_BU',      'EUREX',  'ISE',      'STOXX', 'EEI_AM',
            'BI',     'FSE',          'MEFF',     'SYNEURONEXT', 'EEI_LI', 'SYNSTOXX', 'BM',    'IDM',
            'BM_OTC', 'EURONEXT_OTC', 'FSE_OTC',  'STOXX_OTC'
        ],
        'GBP' => ['ICE_LIFFE', 'LSE', 'SYNLSE', 'FS', 'LSE_OTC'],
        'HKD' => ['HKF', 'HKSE', 'HKSE_OTC'],
        'IDR' => ['JSC'],
        'INR' => ['BSE',    'NSE',   'NSE_OTC'],
        'JPY' => ['SYNTSE', 'TSE_S', 'TSE', 'OSE', 'TSE_OTC'],
        'KRW' => ['KRX'],
        'KWD' => ['KSE'],
        'NOK' => ['OSLO'],
        'NZD' => ['NZSE'],
        'RUB' => ['MICEX'],
        'SAR' => ['SAS'],
        'SEK' => ['OMX'],
        'SGD' => ['SES', 'SGX', 'SGX_OTC'],
        'TRY' => ['BIS'],
        'USD' => [
            'NYSE_SPC',     'SYNNYSE_SPC',      'NYSE',             'MOF',    'NASDAQ_INDEX', 'CME',
            'RTS',          'ODLS',             'SP_GLOBAL',        'NASDAQ', 'SYNNYSE_DJI',  'SP_GSCI',
            'OIL_OTC',      'BRENT_OTC',        'CME_OTC',          'ICE',    'NASDAQ_OTC',   'NYSE_OTC',
            'NYSE_SPC_OTC', 'RSI_FOREX_EURUSD', 'RSI_FOREX_GBPUSD', 'RSI_FOREX_USDJPY'
        ],
        'ZAR' => ['JSE', 'JSE_OTC'],
    };
    my %undef_currency_exchanges = (
        RANDOM          => 1,
        FOREX           => 1,
        METAL           => 1,
        RANDOM_NOCTURNE => 1,
        CRYPTOCURRENCY  => 1,
        RSI_CRYPTO      => 1,
        RSI_METAL       => 1
    );

    foreach my $ex (map { Finance::Exchange->create_exchange($_) } @exchanges) {
        if (not $ex->currency and exists $undef_currency_exchanges{$ex->symbol}) {
            pass('Currency is undefined for ' . $ex->symbol);
        } elsif (grep { $ex->symbol eq $_ } @{$expected->{$ex->currency}}) {
            pass('currency matched for ' . $ex->symbol);
        } else {
            fail('Wrong currency found for ' . $ex->symbol . ' should be ' . $ex->currency);
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
