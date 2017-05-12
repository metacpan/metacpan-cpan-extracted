use strict;
use warnings;
use Test::More;
use t::Internal;

my $client = t::Internal->new(path => 't/fcgi/post.fcgi');
my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD => 'POST',
        QUERY_STRING   => 'foo=bar',
    },
    "wow\n"
);
is $stdout, "Content−type: text/html\r\n\r\nhello: wow\n";
is $stderr, undef;

done_testing;
