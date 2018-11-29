#!perl

use strict;
use warnings;

use HTTP::Tiny::FromHTTPRequest;

use Test::More;

{
  no warnings 'redefine';
  *HTTP::Tiny::request = sub { return @_ };
}

my $ua = HTTP::Tiny::FromHTTPRequest->new;

{
    my ($obj, $type, $url, $data) = $ua->request( HTTP::Request->parse(<<'REQUEST') );
GET http://perl-services.de HTTP/1.1
REQUEST

    is $type, 'GET';
    is $url,  'http://perl-services.de';
}

{
    my ($obj, $type, $url, $data) = $ua->request( 'get', 'http://perl-services.de' );

    is $type, 'get';
    is $url,  'http://perl-services.de';
    is $data, undef;
}

{
    my $options = { headers => { 'Accept-Charset' => 'utf-8' } };
    my ($obj, $type, $url, $data) = $ua->request( 'get', 'http://perl-services.de', $options  );

    is $type, 'get';
    is $url,  'http://perl-services.de';
    is_deeply $data, $options;
}

done_testing();
