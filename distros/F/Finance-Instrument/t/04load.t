#!perl -w
use strict;
use Test::More;

use Finance::Instrument::Domain;
use Finance::Instrument::Futures;

my $d = Finance::Instrument::Domain->new;
$d->load_default_exchanges;
$d->load_default_instrument('futures/XHKF.HSI');
my $futures = $d->get('XHKF.HSI');
my $hkfe = $d->get_exchange('XHKF');
$hkfe->attr('my_broker1.exchange_id', 'HKFE');
$hkfe->attr('my_broker2.exchange_id', 'HKF');
is($futures->attr('my_broker1.exchange_id'), 'HKFE');
is($futures->attr('my_broker2.exchange_id'), 'HKF');
done_testing;
