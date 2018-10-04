#!perl -w
use strict;
use Test::More tests => 2;
use Meetup::API;
my $m = Meetup::API->new(
    API_BASE => 'http://example.com/api',
    api_key => 'suuper-secret',
    url_map => {
        test => '/v1/{testing}/test',
    },
);

is $m->url_for('test', testing => 1, foo => 'bar?'),
   'http://example.com/api/v1/1/test?key=suuper-secret&sign=true&foo=bar%3F',
   'Basic parameter URL building works';

is $m->url_for('test', testing => 'foo/bar', foo => 'bar?'),
   'http://example.com/api/v1/foo%2Fbar/test?key=suuper-secret&sign=true&foo=bar%3F',
   'Basic parameter URL building works for URLs as well';