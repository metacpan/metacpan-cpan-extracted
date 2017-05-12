use strict;
use warnings;
use Test::More;
use t::Internal;

my $client = t::Internal->new(path => 't/fcgi/big_post.fcgi');

for my $len (85_556, 1_000_000) {
    my $chunk = "abcdefg" x $len;
    my ( $stdout, $stderr ) = $client->request(
        +{
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => 'foo=bar',
            CONTENT_TYPE => 'application/octet-stream',
            CONTENT_LENGTH => length($chunk),
        },
        $chunk,
        10
    );
    is $stdout, "Content−Type: application/octet-stream\r\nContent-Length: @{[ length($chunk) ]}\r\n\r\n$chunk";
    my ($x1, $x2) = $stderr =~ /len: (\d+), (\d+)\n/;
    is $x1, $x2;
    is $x1, length($chunk);
}

done_testing;
