#!perl
use strict;
use Test::More;

use DateTime;

use Finance::Instrument::Futures;
use Finance::Instrument;

my $exchange = Finance::Instrument::Exchange->new( code => 'XHKF',
                                                   name => 'HKFE',
                                               );
my $futures = Finance::Instrument::Futures->new( code => 'HSI',
                                                 name => 'HSI',
                                                 exchange => $exchange,
                                                 tick_size => 1,
                                                 multiplier => 50,
                                                 time_zone => 'Asia/Hong_Kong',
                                                 currency => 'HKD',
                                                 session => [[555, 720], [810, 975]],
                                                 last_day_close => 15,
                                                 override_since => {
                                                     '1970-01-01' => {
                                                         'session' => [[585, 750], [870, 975]],
                                                     },
                                                     '2011-03-07' => {
                                                         'session' => [[555, 720], [810, 975]],
                                                     },
                                                     '2012-03-05' => {
                                                         'session' => [[555, 720], [780, 975]],
                                                     },
                                                 },
                                                 contract_calendar => {
                                                     201112 => {
                                                         last_trading_day => '2011-12-29',
                                                     },
                                                     201201 => {
                                                         last_trading_day => '2012-01-30',
                                                     },
                                                     201202 => {
                                                         last_trading_day => '2012-02-28',
                                                     }
                                                 });

$futures->attr('archivedir', '/tmp');
$exchange->attr('is_naughty', 1);

is($futures->attr('archivedir'), '/tmp');
is($futures->attr('is_naughty'), 1);
my $dt = DateTime->new(year => 2012, month => 1, day => 10,
                       hour => 16, minute => 15, second => 0,
                       time_zone => 'Asia/Hong_Kong');
my $fc = $futures->near_term_contract($dt);
is($fc->attr('is_naughty'), 1);

is($fc->attr('archivedir'), '/tmp');

is($fc->tick_size, 1);
is($fc->exchange, $exchange);

is($fc->expiry, '201201');
is($fc->last_trading_day->ymd, '2012-01-30');
my ($session, $date, $idx) = $fc->derive_session($dt);

is_deeply($session, [[555, 720], [810, 975]]);

is($date->ymd, '2012-01-10');
is($idx, 1);

($session, $date, $idx) = $fc->derive_session($dt->clone->add(hours => 1));
is_deeply($session, [[555, 720], [810, 975]]);
is($date->ymd, '2012-01-11');
is($idx, 0);

($session, $date, $idx) = $fc->derive_session($dt->clone->subtract(years => 1, hours => 8));
is_deeply($session, [[585, 750], [870, 975]]);
is($date->ymd, '2011-01-10');
is($idx, 0);

my $time = $fc->trading_time_for_day($dt);
is_deeply($time, [[1326158100, 1326168000], [1326173400, 1326183300]]);

done_testing;
