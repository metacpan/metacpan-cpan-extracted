#!/usr/bin/env perl
use Test2::V0;

use Scalar::Util qw(looks_like_number);
use Finance::Currency::Convert::Esunbank qw(get_currencies convert_currency);

unless ($ENV{TEST_LIVE}) {
    skip_all('Live testing. Set TEST_LIVE=1 to enable.');
}

subtest 'get_currencies' => sub {
    my ($error, $result) = get_currencies();

    if (defined($error)) {
        is $result, U(), "Result is undef becasue we encounter errors";
    } else {
        is $result, D(), "Result is defined because we encounter no errors";
        is $result, bag {
            all_items hash {
                field 'currency', D();
                field 'zh_currency_name', D();
                field 'en_currency_name', D();
                field 'buy_at', D();
                field 'sell_at', D();
                end();
            };
        }, 'The return value is an ArrayRef[Rate]';
    }
};

subtest 'convert_currency' => sub {
    my ($error, $result) = convert_currency(10, 'USD', 'TWD');

    if (defined($error)) {
        is $result, U(), "Result is undef becasue we encounter errors";
    } else {
        is $result, D(), "Result is defined because we encounter no errors";
        ok looks_like_number($result);
        ok $result > 10, "10 USD usually costs more than 10 TWD";
        note "10 USD = $result TWD now";
    }
};

done_testing;
