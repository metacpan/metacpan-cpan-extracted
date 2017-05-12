#!perl
use strict;
use Test::More;

use DateTime;

use Finance::Instrument::Futures;
use Finance::Instrument;

my $exchange = Finance::Instrument::Exchange->new( code => 'XSES',
                                                   name => 'SGX',
                                               );
my $futures = Finance::Instrument::Futures->new( code => 'TW',
                                                 name => 'TW',
                                                 exchange => $exchange,
                                                 tick_size => 0.1,
                                                 multiplier => 100,
                                                 time_zone => 'Asia/Singapore',
                                                 currency => 'USD',
                                                 session => [[525, 830], [875, 1500]],
                                                 last_day_close => 830,
                                             );
my $dt = DateTime->new(year => 2012, month => 1, day => 10,
                       time_zone => 'Asia/Singapore');
my ($session, $date, $idx) = $futures->derive_session($dt);

is_deeply($session, [[525, 830], [875, 1500]]);
is($date->ymd, '2012-01-09');
is($idx, 1);

done_testing;
