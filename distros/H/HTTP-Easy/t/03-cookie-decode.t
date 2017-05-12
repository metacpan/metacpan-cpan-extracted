#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More tests => 16;

my $mod = 'HTTP::Easy::Cookies';
{no strict; ${$mod.'::NO_XS'} = 1;}
use_ok $mod;

my $p;
is_deeply
	$p = $mod->decode(
	"BAD=1234567890; Expires=Fri, 31-Dec-2010 23:59:59 GMT; path=/; domain=.example.net; HttpOnly; MyCustomFlag; comment=0".
	", RMID=1234567890; Expires=Fri, 31-Dec-2010 23:59:59 GMT; path=/; domain=.test.me; HttpOnly; MyCustomFlag; comment=0".
	", RSID=123".
	", SOME=0 ; path=/test".
	"; DummyKey=DummyValue", host => 'test.me'),
	{
		version => 1,
		".test.me" => {
			"/" => { RMID => {
				value => "1234567890",
				mycustomflag => 1,
				httponly => 1,
				comment => 0,
				expires => 1293839999,#"Fri, 31-Dec-2010 23:59:59 GMT"
			}}
		},
		"test.me" => {
			"/" => {
				RSID => { value => 123 },
				DummyKey => { value => "DummyValue" },
			},
			"/test" => { SOME => { value => 0 } }
		},
	},
	'4 keys, different separators, customflag',
or diag explain $p;

is_deeply
	$p = $mod->decode('fo o=ba r; Secure; HttpOnly; Comment=lalalala'),
	{ "" => { "/" => {
      "fo o" => {
        comment => "lalalala",
        value => "ba r",
        secure => 1,
        httponly => 1
		}}},
		version => 1
	},
	'wsp key, wsp value, secure, httponly, comment',
or diag explain $p;

$p = $mod->decode('foo="bar"; Expires=Fri, 31-Dec-2010 23:59:59; HttpOnly, later="ok"');
is $p->{''}{'/'}{foo}{value}, 'bar', 'foo value'    or diag explain $p;
ok $p->{''}{'/'}{foo}{httponly}, 'foo.httponly'     or diag explain $p;
is $p->{''}{'/'}{later}{value}, 'ok', 'later value' or diag explain $p;

is_deeply
	$p = $mod->decode('foo=ba r; Version=1; Domain=kraih.com; Path=/test;'
      . ' Max-Age=60; expires=Thu, 07 Aug 2008 07:07:59 GMT;'
      . ' Port="80 8080"; Secure; HttpOnly; Comment=lalalala',
	),
{
  ".kraih.com" => {
    "/test" => {
      foo => {
        version => 1,
        value => "ba r",
        secure => 1,
        port => "80 8080",
        "max-age" => 60,
        comment => "lalalala",
        httponly => 1,
        expires => 1218092879,#"Thu, 07 Aug 2008 07:07:59 GMT"
      }
    }
  },
  version => 1
},
	'mojo testcase',
	or diag explain $p;



$p = $mod->decode('fo o=ba r;x = y');
is_deeply
	$p,
{
  '' => { '/' => {
      x => { value => "y" },
      "fo o" => { value => "ba r" },
  }},
  version => 1
},
'bad separator: ;'
or diag explain $p;

is_deeply
	$p = $mod->decode( 'x=x:1276995413%22; path=/; expires=Thu, 31-Dec-37 23:55:55 GMT;HttpOnly', host => 'test.me',),
	{ 'test.me' => { '/' => {
		x => { value => 'x:1276995413"', httponly => 1, expires => 'Thu, 31-Dec-37 23:55:55 GMT' }
	}}, version => 1 },
	'decode2' or diag explain $p;

is_deeply
	$p = $mod->decode( 'id1=1; path=/;', host => 'test.me',),
	{ 'test.me' => { '/' => {
		id1 => { value => 1 }
	}}, version => 1 },
	'decode1' or diag explain $p;


is_deeply
	$p->decode( 'id2=2; path=/;', host => 'test.me',),
	{
		'test.me' => {
			'/' => {
				id1 => { value => 1 },
				id2 => { value => 2 },
			}
		},
		version => 1,
	},
	'object.decode1' or diag explain $p;

is_deeply
	$p->decode( 'id1=2; path=/;', host => 'test.xx',),
	{
		'test.me' => {
			'/' => {
				id1 => { value => 1 },
				id2 => { value => 2 },
			}
		},
		'test.xx' => {
			'/' => { id1 => { value => 2 } }
		},
		version => 1,
	},
	'object.decode2' or diag explain $p;

is_deeply
	$p->decode( 'id1=3; path=/test;', host => 'test.xx',),
	{
		'test.me' => { '/' => { id1 => { value => 1 }, id2 => { value => 2 } } },
		'test.xx' => {
			'/'     => { id1 => { value => 2 } },
			'/test' => { id1 => { value => 3 } },
		},
	version => 1 },
	'object.decode3' or diag explain $p;

is_deeply
	$p->decode( 'id1=4; path=/test;', host => 'test.xx',),
	{
		'test.me' => { '/' => { id1 => { value => 1 }, id2 => { value => 2 } } },
		'test.xx' => {
			'/'     => { id1 => { value => 2 } },
			'/test' => { id1 => { value => 4 } },
		},
	version => 1 },
	'object.decode4' or diag explain $p;

is_deeply
	$p->decode( 'id1=""; path=/test;', host => 'test.xx',),
	{
		'test.me' => { '/' => { id1 => { value => 1 }, id2 => { value => 2 } } },
		'test.xx' => {
			'/'     => { id1 => { value => 2 } },
		},
	version => 1 },
	'object.decode5' or diag explain $p;

#warn explain $p;
is_deeply
	$p = $mod->decode(
		'PREF=ID=111:NW=1:TM=11:LM=22:S=-bBPlnkUvqt0fym8; expires=Mon, 16-Apr-2012 23:09:24 GMT; path=/; domain=.google.ru',
		host => 'www.google.ru',
	),
	{
		'.google.ru' => {
			'/' => {
				'PREF' => {
					'expires' => 1334617764,
					'value' => 'ID=111:NW=1:TM=11:LM=22:S=-bBPlnkUvqt0fym8'
				}
			}
		},
		version => 1
	},
	'google cookie' or diag explain $p;
