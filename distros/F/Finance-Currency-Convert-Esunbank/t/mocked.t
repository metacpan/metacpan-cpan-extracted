#!/usr/bin/env perl
use Test2::V0;

use Scalar::Util qw(looks_like_number);
use Finance::Currency::Convert::Esunbank qw(get_currencies convert_currency);
use Mojo::UserAgent;

my $guard = mock 'Finance::Currency::Convert::Esunbank' => (
    override => [
        '_fetch_currency_exchange_web_page' => sub {
            die "Fake error";
        }
    ]
);

subtest 'get_currencies' => sub {
    my ($error, $result) = get_currencies();
    is $error, D();
    is $result, U();
};

subtest 'convert_currency' => sub {
    my ($error, $result) = convert_currency(1, 'USD', 'TWD');
    is $error, D();
    is $result, U();
};

done_testing;
