
use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Async;
use URI;

my $full_url = URI->new('http://www.test.com:8080/foo/bar?baz=bundy');

my @tests = (
    'http://www.test.com:8080/foo/bar?baz=bundy', '/foo/bar?baz=bundy',
    'bar?baz=bundy',                              '?baz=bundy',
);

foreach my $test (@tests) {
    my $url = HTTP::Async::_make_url_absolute(
        url => $test,
        ref => $full_url,
    );

    is "$url", "$full_url", "$test -> $full_url";
}
