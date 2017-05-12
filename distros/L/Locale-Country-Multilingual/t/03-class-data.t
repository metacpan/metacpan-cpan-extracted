#!perl -T

use Test::More tests => 5;

use Locale::Country::Multilingual;

cmp_ok(scalar(keys %{Locale::Country::Multilingual->languages}), '==', 0, 'no languages loaded');

load('en');

is_deeply([sort keys %{Locale::Country::Multilingual->languages}], [qw(en)], 'language en loaded successfully');

load('zh_TW');

is_deeply([sort keys %{Locale::Country::Multilingual->languages}], [qw(en zh-tw)], 'language en and zh-tw both loaded');

load('it');

is_deeply([sort keys %{Locale::Country::Multilingual->languages}], [qw(en it zh-tw)], 'language en, it and zh-tw all loaded');

load('zh_CN');

is_deeply([sort keys %{Locale::Country::Multilingual->languages}], [qw(en it zh zh-tw)], 'language en, it, zh and zh-tw all loaded');


sub load {
    my $lang = shift;

    # create an object, load language data and go out of scope
    my @volatile = Locale::Country::Multilingual
	->new(lang => $lang)
	->all_country_codes;

    return;
}
