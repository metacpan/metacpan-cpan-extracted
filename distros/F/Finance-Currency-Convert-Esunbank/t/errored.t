#!/usr/bin/env perl
use Test2::V0;

use Finance::Currency::Convert::Esunbank qw(convert_currency);

subtest 'convert_currency' => sub {
    my ($error, $result) = convert_currency(1, 'USD', 'USD');
    is $error, D();
    is $result, U();
};

done_testing;
