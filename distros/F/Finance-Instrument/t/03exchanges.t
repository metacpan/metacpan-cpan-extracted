#!perl -w
use strict;
use Test::More;

use DateTime;

use Finance::Instrument::Domain;
use Finance::Instrument::Futures;

my $d = Finance::Instrument::Domain->new;
$d->load_default_exchanges;

my $hkfe = $d->get_exchange('XHKF');
$hkfe->attr('exchange_id.my_broker', 'HKFE');

my $futures = Finance::Instrument::Futures->new( code => 'HSI',
                                                 name => 'HSI',
                                                 exchange => $hkfe,
                                                 tick_size => 1,
                                                 multiplier => 50,
                                                 time_zone => 'Asia/Hong_Kong',
                                                 currency => 'HKD',
                                                 sessions => [[555, 720], [810, 975]],
                                             );
is($futures->attr('exchange_id.my_broker'), 'HKFE');

done_testing;
