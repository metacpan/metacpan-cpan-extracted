#!/usr/bin/perl -w
use strict;
use lib 'inc';
use Test::More;
use MyTestFramework;

plan tests => 1+blocks;

use_ok "HTTP::Request::FromTemplate";

run \&template_identity;

__DATA__
=== Basic GET URL test
--- template
GET http://[% host %][% path %] HTTP/1.0
--- data eval
{
  'host' => 'www.example.com',
  'path' => '/',
}
--- expected
GET http://www.example.com/ HTTP/1.0

=== Basic GET URL test with some parameter
--- template
GET http://[% host %][% path %] HTTP/1.0
Host: [% host %]
Foo: Bar
--- data eval
{
  'host' => 'www.example.com',
  'path' => '/',
}
--- expected
GET http://www.example.com/ HTTP/1.0
Host: www.example.com
Foo: Bar

--- end
