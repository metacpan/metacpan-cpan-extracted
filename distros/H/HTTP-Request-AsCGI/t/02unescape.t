use strict;
use warnings;
use HTTP::Request::AsCGI;
use Test::More tests => 1;

is(
  HTTP::Request::AsCGI::_uri_safe_unescape('%2Fhello%20there'),
  '%2Fhello there',
  'do not unescape reserved characters',
);
