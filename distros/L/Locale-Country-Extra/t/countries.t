#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Test::More (tests => 10);
use Test::NoWarnings;
use Locale::Country::Extra;

my $countries = Locale::Country::Extra->new();

subtest 'country_from_code' => sub {
    is $countries->country_from_code('au'), 'Australia',      'AU is Australia';
    is $countries->country_from_code('gb'), 'United Kingdom', 'GB is United Kingdom';
    is $countries->country_from_code('id'), 'Indonesia',      'ID is Indonesia';
    is $countries->country_from_code('AU'), 'Australia',      'AU is Australia';
    is $countries->country_from_code('GB'), 'United Kingdom', 'GB is United Kingdom';
    is $countries->country_from_code('ID'), 'Indonesia',      'ID is Indonesia';

    is $countries->country_from_code('uk'), 'United Kingdom', 'uk is also United Kingdom';
};

subtest 'code_from_country' => sub {
    is $countries->code_from_country('Australia'),       'au',  'Australia is AU';
    is $countries->code_from_country('United Kingdom'),  'gb',  'United Kingdom is GB';
    is $countries->code_from_country('Indonesia'),       'id',  'Indonesia is ID';
    is $countries->code_from_country("austraLIA"),       'au',  "australia case insensitive";
    is $countries->code_from_country("nonexistent"),     undef, "test nonexistent  country ";
    is $countries->code_from_country("Macau SAR China"), 'mo',  "Macau SAR China is Macau";
    is $countries->code_from_country("Macau"),           'mo',  "Macau also mo";
};

subtest 'country_from_mt5' => sub {
    is $countries->code_from_country("Brunei Darussalam"),                 "bn", "Brunei Darussalam is bn";
    is $countries->code_from_country("Cocos Islands"),                     "cc", "Cocos Islands is cc";
    is $countries->code_from_country("Congo"),                             "cg", "Congo is cg";
    is $countries->code_from_country("Heard Island and Mcdonald Islands"), "hm", "Heard Island and Mcdonald Islands is hm";
    is $countries->code_from_country("Hong Kong S.A.R."),                  "hk", "Hong Kong S.A.R. is hk";
    is $countries->code_from_country("Korea"),                             "kr", "Korea is kr";
    is $countries->code_from_country("Macao S.A.R."),                      "mo", "Macao S.A.R. is mo";
    is $countries->code_from_country("Myanmar"),                           "mm", "Myanmar is mm";
    is $countries->code_from_country("Islamic Republic of Pakistan"),      "pk", "Islamic Republic of Pakistan is pk";
    is $countries->code_from_country("Palestinian Authority"),             "ps", "Palestinian Authority is ps";
    is $countries->code_from_country("Pitcairn"),                          "pn", "Pitcairn is pn";
    is $countries->code_from_country("Saint Vincent and The Grenadines"),  "vc", "Saint Vincent and The Grenadines is vc";
    is $countries->code_from_country("South Georgia"),                     "gs", "South Georgia is gs";
    is $countries->code_from_country("Syrian Arab Republic"),              "sy", "Syrian Arab Republic is sy";
    is $countries->code_from_country("U.A.E."),                            "ae", "U.A.E. is ae";
    is $countries->code_from_country("Vatican City State"),                "va", "Vatican City State is va";
    is $countries->code_from_country("Virgin Islands"),                    "vg", "Virgin Islands is vg";
};

subtest 'idd_from_code' => sub {
    is $countries->idd_from_code('us'), '1',    'US is idd 1';
    is $countries->idd_from_code('ai'), '1264', 'AI is idd 1264';
    is $countries->idd_from_code('gb'), '44',   'GB is idd 44';
    is $countries->idd_from_code('in'), '91',   'IN is idd 91';
    is $countries->idd_from_code('US'), '1',    'US is idd 1';
    is $countries->idd_from_code('AI'), '1264', 'AI is idd 1264';
    is $countries->idd_from_code('GB'), '44',   'GB is idd 44';
    is $countries->idd_from_code('IN'), '91',   'IN is idd 91';
    is $countries->idd_from_code('uk'), '44',   'uk is idd 44';
    is $countries->idd_from_code('im'), '44',   'im is idd 44';
};

subtest 'code_from_phone' => sub {
    is $countries->code_from_phone('001222694669'),      'us', '001222694669 is from US';
    is $countries->code_from_phone('+1 264 99922211'),   'ai', '+1 264 99922211 is from AI';
    is $countries->code_from_phone('+44 8882220202'),    'gb', '+44 8882220202 is from GB';
    is $countries->code_from_phone('11111118882220202'), '',   '11111118882220202 returns empty string';
};

subtest 'codes_from_phone' => sub {
    my @expected = qw(us);
    is_deeply $countries->codes_from_phone('001222694669'), \@expected, '001222694669 is from US';
    @expected = qw(ai us);
    is_deeply $countries->codes_from_phone('+1 264 99922211'), \@expected, '+1 264 99922211 is from AI';
    @expected = qw(gb im);
    is_deeply $countries->codes_from_phone('+44 8882220202'), \@expected, '+44 8882220202 is from GB or IM';
};

subtest 'all_country_names' => sub {
    my @all_names = $countries->all_country_names;
    is scalar @all_names, 249, 'all_country_names returns 249 countries';
};

subtest 'all_country_codes' => sub {
    my @all_codes = $countries->all_country_codes;
    is scalar @all_codes, 249, 'all_country_codes returns 249';
};

subtest 'localized_code2country' => sub {
    my $c = $countries->localized_code2country('id', 'en');
    is $c, 'Indonesia', 'id is Indonesia';
};

