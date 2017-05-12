#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More tests => 8;
use URI;

my $mod = 'HTTP::Easy::Headers';
{no strict; ${$mod.'::NO_XS'} = 1;}
use_ok $mod;

my $hash;
my $h = "Connection: close\015\012".
        "Expect: continue-100\015\012".
        "Content-Type: text/html";

$hash = $mod->decode($h);

is($hash->{connection},     'close',        'right value');
is($hash->{expect},         'continue-100', 'right value');
is($hash->{'content-type'}, 'text/html',    'right value');

# garbled
$h = "Host:www.ru\012".
     "Host:another.com\012".
     "DaTe:  somedate  \012".
     "X-Someval: some part\012".
         "\t  continue\012".
     "Test";
is_deeply
	$hash = $mod->decode($h),
	{
		date => "somedate",
		"x-someval" => "some part continue",
		host => "www.ru,another.com"
	},
	'garbled+unfold'
	or diag explain $hash
	;

is
	$mod->decode(
		"Location: http://somewhere.com\n",
		base => URI->new('http://test.me/test/'),
	)->{location},
	'http://somewhere.com',
	'absolue location';

is
	$mod->decode(
		"Location: /somewhere",
		base => URI->new('http://test.me:81/test/?test=1'),
	)->{location},
	'http://test.me:81/somewhere',
	'/relative location + port';

is
	$mod->decode(
		"Location: ./somewhere",
		base => URI->new('http://test.me/test/'),
	)->{location},
	'http://test.me/test/somewhere',
	'./relative location';
