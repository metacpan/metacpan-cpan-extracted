#!/usr/bin/perl -w
use strict;
use lib 'inc';
use Test::More;
use MyTestFramework;

plan tests => 1+blocks;

use_ok "HTTP::Request::FromTemplate";

run \&template_identity;

__DATA__
=== Content-Length
--- template
POST http://[% host %][% path %][% query %] HTTP/1.1
Host: [% host %]
Connection: keep-alive
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Accept-Encoding: gzip,deflate
Accept-Language: en-us,en;q=0.5
User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Keep-Alive: 300
Referer: http://[% host %][% path %][% query %]
Content-Type: application/x-www-form-urlencoded
Content-Length: [% content_length %]

node_id=3628&op=message&message=[% message %]&message_send=talk
--- data eval
{
  'host' => 'perlmonks.org',
  'path' => '/',
  'query' => '?',
  message => 'Hello%20World',
}
--- expected
POST http://perlmonks.org/? HTTP/1.1
Connection: keep-alive
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Accept-Encoding: gzip,deflate
Accept-Language: en-us,en;q=0.5
Host: perlmonks.org
Referer: http://perlmonks.org/?
User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7
Content-Length: 64
Content-Type: application/x-www-form-urlencoded
Keep-Alive: 300

node_id=3628&op=message&message=Hello%20World&message_send=talk

