use strict;
use warnings;
use Test::More;
use t::Internal;

my $client = t::Internal->new(path => 't/fcgi/hello.fcgi');
my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'foo=' . ('0' x 125),
        'HTTP_X_FOO' . ('0' x 125) => 1,
    },
    ''
);
is $stdout, "Content−type: text/html\r\n\r\nhello\nfoo=".('0'x125);
is $stderr, "hello, stderr\n";

done_testing;
