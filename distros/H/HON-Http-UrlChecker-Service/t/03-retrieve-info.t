use strict;
use warnings;

use HTTP::Response;

use HON::Http::UrlChecker::Service qw/p_parseResponse/;

use Test::More tests => 2;

my $response = HTTP::Response->new(200, 'OK');
$response->header(
  date           => 'Sat, 25 Jun 2016 16:38:00 GMT',
  server         => 'Apache',
  content_length => 666,
);

my $expectedResult = [{
  code    => 200,
  date    => 'Sat, 25 Jun 2016 16:38:00 GMT',
  server  => 'Apache',
  message => 'Ok',
}];

my @list = p_parseResponse($response);
is_deeply(\@list, $expectedResult, 'retrieve response 200');

my $redirect = HTTP::Response->new(301, 'Moved Permanently');
$redirect->header(
  date           => 'Sat, 25 Jun 2016 16:37:59 GMT',
  server         => 'Apache',
  content_length => 5151,
);
$response->previous($redirect);

$expectedResult = [{
  code    => 301,
  date    => 'Sat, 25 Jun 2016 16:37:59 GMT',
  server  => 'Apache',
  message => 'Moved Permanently',
},
{
  code    => 200,
  date    => 'Sat, 25 Jun 2016 16:38:00 GMT',
  server  => 'Apache',
  message => 'Ok',
}];

@list = p_parseResponse($response);
is_deeply(\@list, $expectedResult, 'retrieve response 301');
