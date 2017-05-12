#!/usr/bin/perl -w
use strict;
use Test::Exception;
use Test::More tests => 14;
use ok 'Finance::TW::TAIFEX';
use ok 'Finance::TW::TAIFEX::Contract';

my $t = Finance::TW::TAIFEX->new({ year => 2009, month => 12, day => 25});

my $p = $t->product('TX');

isa_ok($p, 'Finance::TW::TAIFEX::Product');
is( $p->near_term($t->context_date), '201001' );

is( $p->near_term(DateTime->new(year => 2009, month => 12, day => 16)),
    '200912' );

is( $p->near_term(DateTime->new(year => 2010, month => 2, day => 22)),
    '201002' );

is( $p->near_term(DateTime->new(year => 2010, month => 2, day => 23)),
    '201003' );

my $c = $t->contract('TX', 2010, 2);

isa_ok($c, 'Finance::TW::TAIFEX::Contract');

is($c->settlement_day->ymd, '2010-02-22');

ok( $c->is_settlement_day(DateTime->new(year => 2010, month => 2, day => 22)) );

is($c->encode, 'G0');
is($c->encode_local, 'B0');

throws_ok {
    $t->contract('TXX', 2010, 2)
} qr/unknown product/;

throws_ok {
    $t->contract('TX', '2999')
} qr/doesn't look like a contract month/;
