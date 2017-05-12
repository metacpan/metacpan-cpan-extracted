use strict;
use warnings;
use Test::More;
use t::Internal;

my $client = t::Internal->new(path => 't/fcgi/hello.fcgi');
my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'foo=bar',
    },
    ''
);
is $stdout, "Content−type: text/html\r\n\r\nhello\nfoo=bar";
is $stderr, "hello, stderr\n";

done_testing;
