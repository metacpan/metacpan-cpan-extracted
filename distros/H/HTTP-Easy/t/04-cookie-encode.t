#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More tests => 13;

my $mod = 'HTTP::Easy::Cookies';
{no strict; ${$mod.'::NO_XS'} = 1;}
use_ok $mod;

my $cj = {
		version => 1,
		".example.net" => {
			"/" => {
				ID => {
					value => "732423sdfs73242",
					expires => 1293839999,#"Fri, 31-Dec-2010 23:59:59 GMT"
				},
				Xv => { value => '\test"'},
			},
			'/path' => { OneMore => { value => 'ok 1' } }
		},
		"test.me" => {
			"/" => {
				ID => { value => 123 },
				DummyKey => { value => "DummyValue" },
			},
			"/test" => { SOME => { value => 0 } }
		},
	};

sub is_ok ($$;$) {
	my ($check,$test,$name) = @_;
	$check = join '; ',sort split /;\040*/, $check if defined $check;
	$test = join '; ', sort split /;\040*/, $test if defined $test;
	is $check,$test,$name;
}

is_ok
	$mod->encode($cj, host => 'example.net'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""},#"
	'.domain + quoting';

is_ok
	$mod->encode($cj, host => 'example.net', path => '/path'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""; OneMore="ok 1"},#"
	'.domain + quoting + path';

is_ok
	$mod->encode($cj, host => 'example.net', path => '/path/inner'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""; OneMore="ok 1"},#"
	'.domain + quoting + inner path';

is_ok
	$mod->encode($cj, host => 'some.example.net'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""},#"
	'sub.domain + quoting';

is_ok
	$mod->encode($cj, host => 'some.example.net', path => '/path'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""; OneMore="ok 1"},#"
	'sub.domain + quoting + path';

is_ok
	$mod->encode($cj, host => 'some.example.net', path => '/path/inner'),
	qq{ID="732423sdfs73242"; Xv="\134\134test\134""; OneMore="ok 1"},#"
	'sub.domain + quoting + inner path';

is_ok
	$mod->encode($cj, host => 'test.me'),
	qq{DummyKey="DummyValue"; ID="123"},#"
	'domain';

is_ok
	$mod->encode($cj, host => 'some.test.me'),
	undef,
	'sub domain';

is_ok
	$mod->encode($cj, host => 'test.me', path => '/test'),
	qq{DummyKey="DummyValue"; ID="123"; SOME="0"},
	'domain + path';

is_ok
	$mod->encode($cj, host => 'test.me', path => '/test/'),
	qq{DummyKey="DummyValue"; ID="123"; SOME="0"},
	'domain + path/';

is_ok
	$mod->encode($cj, host => 'test.me', path => '/test/inner'),
	qq{DummyKey="DummyValue"; ID="123"; SOME="0"},
	'domain + inner path';

is_ok
	$mod->encode($cj, host => 'some.test.me', path => '/test'),
	undef,
	'sub domain + path';

__END__

diag $mod->encode($cj, host => 'some.test.me', path => '/test');

__END__


my $p;
is_deeply
	$p = $mod->decode(
	"RMID=732423sdfs73242; Expires=Fri, 31-Dec-2010 23:59:59 GMT; path=/; domain=.example.net; HttpOnly; MyCustomFlag; comment=0".
	", RSID=123".
	", SOME=0 ; path=/test".
	"; DummyKey=DummyValue", host => 'test.me'),
	{
		version => 1,
		".example.net" => {
			"/" => { RMID => {
				value => "732423sdfs73242",
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
