use strict;
use warnings;
use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan tests => 1;
use CGI;
use HTTP::MobileAttribute::Plugin::Locator;

my $q = CGI->new('foo=bar&foo=baz&dig=dag');
my $got = HTTP::MobileAttribute::Plugin::Locator::_prepare_params(
    $q
);
my $expected = {
    foo => ['bar', 'baz'],
    dig => 'dag',
};
is_deeply $got, $expected;
