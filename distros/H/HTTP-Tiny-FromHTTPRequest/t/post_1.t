#!perl

use strict;
use warnings;

use HTTP::Tiny::FromHTTPRequest;

use Test::More;
use Path::Tiny qw(path);

{
  no warnings 'redefine';
  *HTTP::Tiny::request = sub { return @_ };
}

my $ua      = HTTP::Tiny::FromHTTPRequest->new;
my $content = path( __FILE__ )->sibling( 'assets', 'post_1.txt' )->slurp;

{
    my ($obj, $type, $url, $data) = $ua->request( HTTP::Request->parse($content) );

    is $type, 'POST';
    is $url,  '/';

    is_deeply $data, {
        'headers' => {
            'Content-Type'   => 'multipart/form-data; boundary=go7DX',
            'Content-Length' => '104',
            'Connection'     => 'close',
            'User-Agent'     => 'HTTP-Tiny/0.025'
        },
        'content' => q~--go7DX
Content-Disposition: form-data; name="file"; filename="test.txt"

This is a test
--go7DX--

~,
    };
}

{
    my ($obj, $type, $url, $data) = $ua->request( $content );

    is $type, 'POST';
    is $url,  '/';

    is_deeply $data, {
        'headers' => {
            'Content-Type'   => 'multipart/form-data; boundary=go7DX',
            'Content-Length' => '104',
            'Connection'     => 'close',
            'User-Agent'     => 'HTTP-Tiny/0.025'
        },
        'content' => q~--go7DX
Content-Disposition: form-data; name="file"; filename="test.txt"

This is a test
--go7DX--

~,
    };
}


done_testing();
