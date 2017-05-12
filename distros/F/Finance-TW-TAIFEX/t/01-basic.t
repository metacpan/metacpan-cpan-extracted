#!/usr/bin/perl -w
use strict;
use Test::Exception;
use Test::More tests => 7;
use ok 'Finance::TW::TAIFEX';

my $t = Finance::TW::TAIFEX->new({ year => 2009, month => 12, day => 25});

isa_ok($t, 'Finance::TW::TAIFEX');

is($t->context_date->ymd, '2009-12-25');

ok($t->is_trading_day);

is($t->previous_trading_day, '2009-12-24');

$t->context_date->add(days => 1);
ok(!$t->is_trading_day);

throws_ok {
    $t->previous_trading_day;
} qr/not a known trading day/;
