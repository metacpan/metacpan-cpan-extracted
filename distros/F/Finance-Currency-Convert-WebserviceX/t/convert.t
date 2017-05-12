#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 18;

        my @responses = ('<double>1.23</double>', '<double>1.23</double>', undef);
        Test::MockObject->fake_module('HTTP::Response' => (
            is_success => sub {1;},
            content => sub {return shift @responses}
        ));
        Test::MockObject->fake_module('LWP::UserAgent' => (
            new => sub {return bless {}, shift},
            timeout => sub {},
            env_proxy => sub {},
            get => sub {
                bless {}, 'HTTP::Response'
            }
        ));
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Finance::Currency::Convert::WebserviceX');
};

## return undef is the params are bogus
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    is($cc->convert(), undef);
    is($cc->convert(1), undef);
    is($cc->convert(1, 'asdf'), undef);
    is($cc->convert(undef, 'USD', 'JPY'), undef);
};

## try a conversion. whos knows that the rate result will be
## but at least it will let us know it's a working connection
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    isnt($cc->convert(2.00, 'USD', 'JPY'), undef);
};

## make sure we uc the from/to
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    isnt($cc->convert(2.00, 'usd', 'jpy'), undef);
};

## bug fix. when the from and to are the same, the rate
## returned is 0, so the price returned was 0 instead of
## price * 1
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    is($cc->convert(2.34, 'USD', 'USD'), 2.34);
};

## check cache does not return the same value for different values
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    isnt($cc->convert(1.00, 'USD', 'JPY'), $cc->convert(2.00, 'USD', 'JPY'));
}

## check the cache is properly setup, also for non uc-values
{
    my $cc = Finance::Currency::Convert::WebserviceX->new;
    isa_ok($cc, 'Finance::Currency::Convert::WebserviceX');

    ok(!exists $cc->cache->{'USD-EUR'});
    isnt($cc->convert(1.00, 'usd', 'eur'), undef);
    ok(exists $cc->cache->{'USD-EUR'});
};

