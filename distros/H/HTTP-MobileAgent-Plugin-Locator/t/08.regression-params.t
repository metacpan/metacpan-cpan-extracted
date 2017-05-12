use warnings;
use strict;
use Test::More tests => 1;
use CGI;
use HTTP::MobileAgent::Plugin::Locator;

my $q = CGI->new('foo=bar&foo=baz&dig=dag');
my $got = HTTP::MobileAgent::Plugin::Locator::_prepare_params(
    $q
);
my $expected = {
    foo => ['bar', 'baz'],
    dig => 'dag',
};
is_deeply $got, $expected;
