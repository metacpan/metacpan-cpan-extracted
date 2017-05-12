use strict;
use warnings;
use Test::More;
use t::Internal;

my $client = t::Internal->new(path => 't/fcgi/timeout.fcgi');
eval {
    my ( $stdout, $stderr ) = $client->request(
        +{
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => 'foo=bar',
        },
        ''
    );
};
like $@ => qr/REQUEST_TIME_OUT/;

done_testing;
