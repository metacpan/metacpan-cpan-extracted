#!/usr/bin/perl

use Test::Simple tests => 32;
use Format::Sanitize::Number q/:money/;
use Format::Validate::Number q/:money/;

ok(money(385) eq '385,00');
ok(money(385.00) eq '385,00');
ok(money(385000) eq '385.000,00');
ok(money(3850000) eq '3.850.000,00');
ok(money(3850000.5) eq '3.850.000,5');
ok(money(3850000.56) eq '3.850.000,56');
ok(money(3850000.56665) eq '3.850.000,56665');

ok(money_integer(385) eq '385');
ok(money_integer(385000) eq '385.000');
ok(money_integer(3850000) eq '3.850.000');
ok(money_integer(3850000.00) eq '3.850.000');
ok(money_integer(3850000.5646) eq '3.850.000');

ok(money_decimal eq ',00');
ok(money_decimal(385) eq ',385');
ok(money_decimal(5465564) eq ',5465564');

ok(money_to_int('385,00') == 385);
ok(money_to_int('385,00') == 385.00);
ok(money_to_int('385.000,00') == 385000);
ok(money_to_int('3.850.000,00') == 3850000);
ok(money_to_int('3.850.000,5') == 3850000.5);
ok(money_to_int('3.850.000,56') == 3850000.56);
ok(money_to_int('3.850.000,56665') == 3850000.56665);

ok(looks_like_money '385,00');
ok(looks_like_money '385.000,00');
ok(looks_like_money '3.850.000,00');
ok(looks_like_money '3.850.000,5');
ok(looks_like_money '3.850.000,56');
ok(not looks_like_money '385,,00');
ok(not looks_like_money '3e85,0e0');
ok(not looks_like_money '385..000,00');
ok(not looks_like_money '9.3850.000,5');
ok(not looks_like_money '3.85,0.000,56');