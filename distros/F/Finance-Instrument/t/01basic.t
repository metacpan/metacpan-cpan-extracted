#!perl
use strict;
use Test::More;

use DateTime;

use Finance::Instrument::Futures;
use Finance::Instrument;

my $exchange = Finance::Instrument::Exchange->new( code => 'GLBX',
                                                   name => 'GLOBEX',
                                               );
my $futures = Finance::Instrument::Futures->new( code => '6E',
                                                 name => 'EUR',
                                                 exchange => $exchange,
                                                 tick_size => 0.0001,
                                                 multiplier => 125000,
                                                 time_zone => 'America/Chicago',
                                                 month_cycle => 'HMUZ',
                                                 currency => 'USD',
                                                 session => [[-420, 960]],
                                                 last_day_close => 15,
                                                 contract_calendar => {
                                                     201112 => {
                                                         last_trading_day => '2011-12-19',
                                                     },
                                                     201203 => {
                                                         last_trading_day => '2012-03-19',
                                                     }
                                                 });

my $fc = Finance::Instrument::FuturesContract->new( futures => $futures,
                                                    expiry_month => 12,
                                                    expiry_year => 2011);
is($fc->tick_size, 0.0001);
is($fc->exchange, $exchange);

is($fc->last_trading_day, undef);

my $current = $futures->near_term_contract(DateTime->new(year => 2012, month => 1, day => 10));
is($current->expiry, '201203');
is($current->last_trading_day->ymd, '2012-03-19');

my $previous = $current->previous_contract();
is($previous->expiry, '201112');
is($previous->last_trading_day->ymd, '2011-12-19');

done_testing;
