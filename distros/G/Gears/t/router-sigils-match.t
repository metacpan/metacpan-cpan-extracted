use v5.40;
use Test2::V1 -ipP;

use lib 't/lib';
use Gears::Test::Router;

################################################################################
# This tests whether the sigil-based router matching works, using cases taken
# from Kelp
################################################################################

my $r = Gears::Test::Router->new(
	location_impl => 'Gears::Router::Location::SigilMatch',
);

_match(
	'ignore regex',
	'/\d+',
	yes => {
		'/\d+' => {},
	},
	no => [
		'/0',
	],
);

_match(
	'no placeholders',
	'/bar',
	yes => {
		'/bar' => {},
		'/bar/' => {},
	},
	par => {
		'/bar' => [],
		'/bar/' => [],
	},
);

_match(
	'normal plus optional',
	'/:a/?b',
	yes => {
		'/bar/foo' => {a => 'bar', b => 'foo'},
		'/1/2' => {a => '1', b => '2'},
		'/bar/' => {a => 'bar', b => undef},
		'/bar' => {a => 'bar', b => undef},
	},
	par => {
		'/bar/foo' => [qw/bar foo/],
		'/bar' => ['bar', undef]
	},
	no => ['/bar/foo/baz']
);

_match(
	'optional brackets',
	'/:a/{?b}ing',
	yes => {
		'/bar/ing' => {a => 'bar', b => undef},
		'/bar/hopping' => {a => 'bar', b => 'hopp'}
	},
	par => {
		'/bar/ing' => ['bar', undef],
		'/bar/hopping' => ['bar', 'hopp']
	},
	no => ['/a/b', '/a', '/a/min']
);

_match(
	'wildcard brackets',
	'/:a/{*b}ing/:c',
	yes => {
		'/bar/hop/ping/foo' => {a => 'bar', b => 'hop/p', c => 'foo'},
	},
	par => {
		'/bar/hop/ping/foo' => [qw{bar hop/p foo}]
	}
);

_match(
	'three params unicode',
	'/:a/:b/:c',
	yes => {
		'/a/b/c' => {a => 'a', b => 'b', c => 'c'},
		'/a-a/b-b/c-c' => {a => 'a-a', b => 'b-b', c => 'c-c'},
		'/12/23/34' => {a => '12', b => '23', c => '34'},
		'/бар/фу/баз' => {a => 'бар', b => 'фу', c => 'баз'},
		"/référence/Français/d'œuf" => {a => 'référence', b => 'Français', c => "d'œuf"},
		'/რეგიონების/მიხედვით/არსებობს' =>
			{a => 'რეგიონების', b => 'მიხედვით', c => 'არსებობს'},
	}
);

_match(
	'two params',
	'/:a/:b',
	yes => {
		'/bar/foo' => {a => 'bar', b => 'foo'},
		'/1/2' => {a => '1', b => '2'},
		'/bar/foo/' => {a => 'bar', b => 'foo'},
	},
	par => {
		'/bar/foo' => [qw/bar foo/]
	},
	no => ['/bar', '/foo', '/bar/foo/baz']
);

_match(
	'multibrackets',
	'/{:a}b/{:c}d',
	yes => {
		'/barb/food' => {a => 'bar', c => 'foo'},
		'/bazb/fizd' => {a => 'baz', c => 'fiz'},
		'/1b/4d' => {a => '1', c => '4'}
	},
	par => {
		'/barb/food' => [qw/bar foo/],
		'/bazb/fizd' => [qw/baz fiz/],
		'/1b/4d' => [qw/1 4/]
	},
	no => [qw{/barba/food /baz/mood /bab/mac /b/ad /ab/d /b/d}]
);

_match(
	'wildcard in the middle',
	'/:a/*b/:c',
	yes => {
		'/bar/foo/baz/bat' => {a => 'bar', b => 'foo/baz', c => 'bat'},
		'/12/56/ab/blah' => {a => '12', b => '56/ab', c => 'blah'}
	},
	par => {
		'/bar/foo/baz/bat' => [qw{bar foo/baz bat}],
		'/12/56/ab/blah' => [qw{12 56/ab blah}]
	},
	no => [
		qw{
			/bar/bat
		}
	]
);

_match(
	'optional in the middle',
	'/:a/?b/:c',
	yes => {
		'/a/b/c' => {a => 'a', b => 'b', c => 'c'},
		'/a/c' => {a => 'a', b => undef, c => 'c'},
		'/a/c/' => {a => 'a', b => undef, c => 'c'}
	},
	par => {
		'/a/b/c' => [qw/a b c/],
		'/a/c' => ['a', undef, 'c']
	},
	no => [
		qw{
			/a
			/a/b/c/d
		}
	]
);

_match(
	'optional at the end',
	'/aa/?b',
	yes => {
		'/aa' => {b => undef},
		'/aa/' => {b => undef},
		'/aa/b' => {b => 'b'},
	},
	no => [
		'/aaa'
	],
);

_match(
	'wildcard',
	'/r/*x',
	yes => {
		'/r/a' => {x => 'a'},
		'/r/a/b' => {x => 'a/b'},
		'/r/a/b/' => {x => 'a/b/'},
	},
	par => {
		'/r/a' => [qw(a)],
		'/r/a/b' => [qw(a/b)],
	},
	no => [
		qw{
			/
			/r
			/r/
			/r1
			/ar1
		}
	]
);

_match(
	'wildcard and slash',
	'/r*x',
	yes => {
		'/r/' => {x => '/'},
		'/r/a' => {x => '/a'},
		'/r/a/b/' => {x => '/a/b/'},
		'/r1' => {x => '1'},
	},
	par => {
		'/r/' => [qw(/)],
		'/r1' => [qw(1)],
	},
	no => [
		qw{
			/
			/r
			/ar1
		}
	]
);

_match(
	'wildcard in the middle',
	'/r/*x/:a',
	yes => {
		'/r/aa/b' => {x => 'aa', a => 'b'},
		'/r/aa/bb/c' => {x => 'aa/bb', a => 'c'},
	},
	par => {
		'/r/aa/bb/c' => [qw(aa/bb c)],
	},
	no => [
		qw{
			/r/tt/
		}
	]
);

_match(
	'slurpy',
	'/test/>x',
	yes => {
		'/test' => {x => undef},
		'/test/' => {x => undef},
		'/test/a' => {x => 'a'},
		'/test/a/b' => {x => 'a/b'},
		'/test/a/b/' => {x => 'a/b/'},
	},
	par => {
		'/test/' => [undef],
		'/test/a' => ['a'],
		'/test/a/b' => ['a/b'],
		'/test/a/b/' => ['a/b/'],
	},
	no => [
		qw(
			/tes
			/testa
			/tes/t
		)
	],
);

_match(
	'slurpy without slash',
	'/test/a>b',
	yes => {
		'/test/a' => {b => undef},
		'/test/a/' => {b => '/'},
		'/test/ab' => {b => 'b'},
		'/test/a/b' => {b => '/b'},
		'/test/a/b/' => {b => '/b/'},
	},
	no => [
		qw(
			/test/b
			/test/
			/a/test/a
		)
	],
);

_match(
	'defaults',
	'/:a/?b',
	yes => {
		'/bar' => {a => 'bar', b => 'boo'},
		'/bar/foo' => {a => 'bar', b => 'foo'}
	},
	par => {
		'/bar' => [qw/bar boo/],
		'/bar/foo' => [qw/bar foo/]
	},
	no => [
		qw{
			/a/b/c
		}
	],
	defaults => {b => 'boo'}
);

_match(
	'defaults in the middle',
	'/:a/?b/:c',
	yes => {
		'/bar/foo' => {a => 'bar', b => 'boo', c => 'foo'},
		'/bar/moo/foo' => {a => 'bar', b => 'moo', c => 'foo'}
	},
	par => {
		'/bar/foo' => [qw/bar boo foo/],
		'/bar/moo/foo' => [qw/bar moo foo/]
	},
	no => [
		qw{
			/a/b/c/d
			/a
		}
	],
	defaults => {b => 'boo'}
);

_match(
	'checks',
	'/:a/:b',
	yes => {
		'/123/012012' => {a => '123', b => '012012'},
	},
	par => {
		'/123/012012' => [qw/123 012012/],
	},
	no => [
		qw{
			/12/1a
			/1a/12
		}
	],
	checks => {a => '\d+', b => '[0-2]+'}
);

_match(
	'optional checks',
	'/:a/?b',
	yes => {
		'/123/012012' => {a => '123', b => '012012'},
		'/123/' => {a => '123', b => undef},
		'/123' => {a => '123', b => undef}
	},
	par => {
		'/123/012012' => [qw/123 012012/],
		'/123' => ['123', undef]
	},
	no => [
		qw{
			/12/1a
			/1a/12
		}
	],
	checks => {a => '\d+', b => '[0-2]+'}
);

_match(
	'single check',
	'/:a',
	yes => {
		'/1' => {a => '1'},
		'/12' => {a => '12'},
		'/123' => {a => '123'},
	},
	no => [qw{/a /ab /abc /1234 /a12}],
	checks => {a => '\d{1,3}'},
);

_match(
	'partial check',
	'/:a/{?b}ing',
	yes => {
		'/bar/ing' => {a => 'bar', b => undef},
		'/bar/123ing' => {a => 'bar', b => '123'}
	},
	par => {
		'/bar/ing' => ['bar', undef],
		'/bar/123ing' => ['bar', '123']
	},
	no => ['/a/b', '/a', '/a/min', '/a/1234ing'],
	checks => {a => qr/\w{3}/, b => qr/\d{1,3}/},
);

_match(
	'wildcard check',
	'/:a/*c',
	yes => {
		'/abc/69' => {a => 'abc', c => '69'}
	},
	par => {
		'/abc/69' => [qw/abc 69/]
	},
	no => [
		'/high/five5',
		'/123/123',
		'/0/0',
		'/12/a2'
	],
	checks => {a => qr/[^0-9]+/, c => qr/\d{1,2}/},
);

done_testing;

sub _get_match_named ($match)
{
	return {} unless $match;

	my $tokens = $match->location->pattern_obj->tokens;
	my $matched = $match->matched;

	return {
		map { $tokens->[$_]{label} => $matched->[$_] } keys $tokens->@*
	};
}

sub _match ($name, $pattern, %args)
{
	my $yes = delete $args{yes};
	my $no = delete $args{no};
	my $par = delete $args{par};

	$r->clear->add($pattern, \%args);

	subtest "should pass case: $name (yes)" => sub {
		foreach my $case (keys $yes->%*) {
			my $match = $r->match($case)->[0];
			is _get_match_named($match), $yes->{$case}, "$case ok";
		}
		}
		if $yes;

	subtest "should pass case: $name (no)" => sub {
		foreach my $case ($no->@*) {
			my $match = $r->match($case)->[0];
			is $match, undef, "$case ok";
		}
		}
		if $no;

	subtest "should pass case: $name (par)" => sub {
		foreach my $case (keys $par->%*) {
			my $match = $r->match($case)->[0];
			is $match->matched, $par->{$case}, "$case ok";
		}
		}
		if $par;
}

