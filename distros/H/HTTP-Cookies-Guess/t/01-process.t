#!perl -T
use strict;
use warnings;
use FindBin;
use HTTP::Cookies::Guess;
use Test::More tests => 3;

my $cookie_jar;

$cookie_jar = HTTP::Cookies::Guess->create( file => '/tmp/test', type => 'Netscape' );
ok(ref($cookie_jar) eq 'HTTP::Cookies::Netscape');

$cookie_jar = HTTP::Cookies::Guess->create( file => '/tmp/test' );
ok(ref($cookie_jar) eq 'HTTP::Cookies');

$cookie_jar = HTTP::Cookies::Guess->create('/tmp/test');
ok(ref($cookie_jar) eq 'HTTP::Cookies');

