#!/usr/bin/perl -w
# $Id: 02.getopt.t 887 2016-08-29 12:57:34Z schieche $

use 5.016;
use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use Scalar::Util 'blessed';
use Test::More;
use Test::MockObject::Extends;

use Capture::Tiny;

sub capture_stderr(\$&);
sub capture_stderr(\$&)
	{
		my $dest = shift;
		my $code = shift;

		$$dest = Capture::Tiny::capture_stderr(sub {
			$code->();
		});

		return;
	}

our %override;
BEGIN {
	plan tests => 48;

	*CORE::GLOBAL::exit = sub(;$) {
		die [@_] if $override{exit};
		CORE::exit($_[0] // 0);
	};

	use_ok('Getopt::O2');
}

use parent 'Getopt::O2';

# Usage called?
{
	local @ARGV = qw(-h);
	local $override{exit} = 1;

	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);

	$mock->mock(get_option_rules => sub {
		$cmdline->SUPER::get_option_rules,
		'e|enum=?' => ['A choice', 'values' => [qw(foo splort gnarf)]],
		'f|flag' => ['A flag', 'default' => undef],
		'p|param=s' => 'A parameter',
		'n|number=i' => 'A number',
		'single' => 'An exclusively long option',
		'super-califragilistic-expialidocius' => q{
				Even though the sound of it is something
				quiiite atrocious. I can't rap for shit.
				Here's a haiku in one word:
				Stay_the_patient_course_Of_little_worth_is_your_ire_The_network_is_down.
		},
		undef,
		'!t|test' => 'Something negatable'
	});
	eval {capture_stderr $_, sub {
		$mock->getopt({});
	}};
	die $@ if 'ARRAY' ne ref $@;
	is($@->[0], 0, 'usage');
}

# Code coverage #1
{
	my $usage;
	my $cmdline = bless {}, __PACKAGE__;
	$cmdline = $cmdline->new();
	pass('code.coverage.0');

	no warnings 'once';

	local $override{exit} = 1;
	local @ARGV = qw(--garble);

	eval {capture_stderr $usage, sub {
		$cmdline->getopt({});
	}};

	die $@ if 'ARRAY' ne ref $@;
	is($@->[0], 1, 'usage.exit.1');

	eval {capture_stderr $usage, sub {
		$cmdline->usage(0);
	}};

	die $@ if 'ARRAY' ne ref $@;
	is($@->[0], 0, 'usage.exit.0');
}

# Code coverage #2 (not enough rules)
{
	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);

	$mock->mock(get_option_rules => sub {
		return qw(flag)
	});
	eval {$mock->getopt({})};
	like($@, qr/^Not enough rules/, 'code.coverage.1');
}

# Test left-overs
{
	my @args = qw(--flag --param value -- --param value --flag one two three);
	local @ARGV = @args;
	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);
	my (%options, @leftover);

	$mock->mock(get_option_rules => sub {
		'flag' => 'A flag',
		'param=s' => 'A parameter'
	});

	$cmdline->getopt(\%options, \@leftover);
	is($options{flag}, 1, 'param.flag.0');
	is($options{param}, 'value', 'param.value.0');
	ok(@leftover ~~ @args[4..$#args], 'param.leftover.0');
}

# Unnamed parameters
{
	my @args = (qw(foo bar), undef, '', '-', '--');
	local @ARGV = @args;
	my (@out, %options);

	my $cmdline = __PACKAGE__->new();
	$cmdline->getopt(\%options, \@out);

	pop @args; # "--" is not used
	ok(@out ~~ @args, 'param.unnamed.0');
}

# Invalid option spec
{
	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);

	$mock->mock(get_option_rules => sub {
		'invalid=T' => 'Invalid type'
	});

	eval {$mock->getopt({})};
	like($@, qr/^Invalid rule pattern 'invalid=T'/, 'param.invalid.type');
}

# Invalid long parameter
{
	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);
	my %options;

	eval {
		$mock->mock(error => sub {
			my $self = shift;
			my ($fmt, $arg) = @_;

			is($arg, 'snarf', 'param.invalid.long');

			die $mock;
		});

		local @ARGV = qw(--snarf);
		$mock->getopt(\%options);
	};

	die $@ unless blessed($@) && $mock == $@;
}

# Short options bundling and value
{
	local @ARGV = qw(-affoobert -a -bbba);

	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);
	my %options;

	$mock->mock(get_option_rules => sub {
		return
			'f|file=s' => 'File',
			'a|one+' => 'Flag #1',
			'b|two' => 'Flag #2';
	});

	$cmdline->getopt(\%options);

	is($options{one}, 3, 'params.short.bundle.0');
	is($options{two}, 1, 'params.short.bundle.1');
	is('foobert', $options{file}, 'params.short.value');
}

# Short options value after "=" and value as separate argument
{
	local @ARGV = qw(
		--one=two
		--three four
		--list 1 --list 2 --list 3
		--mode single
		--enum a --enum c
	);

	my $cmdline = __PACKAGE__->new();
	my $mock = Test::MockObject::Extends->new($cmdline);
	my %options;

	$mock->mock(get_option_rules => sub {
		return
			'one=s' => 'Value #1',
			'three=s' => 'Value #2',
			'list=s@' => 'List #1',
			'mode=?' => ['Single Enumeration', 'values' => ['single']],
			'enum=?@' => ['Multi Enumeration', 'values' => ['a', 'b', 'c']];
	});

	$cmdline->getopt(\%options);

	is($options{one}, 'two', 'params.long.value.0');
	is($options{three}, 'four', 'params.long.value.1');
	is($options{mode}, 'single', 'params.long.enum.0');
	is(ref $options{list}, 'ARRAY', 'params.long.value.is_ARRAYREF');
	is(join(',', @{$options{list}}), '1,2,3', 'params.long.value.2');
	is(ref $options{enum}, 'ARRAY', 'params.long.enum.is_ARRAYREF');
	is(join(',', @{$options{enum}}), 'a,c', 'params.long.enum.2');
}

# Parameters with values
{
	my %param_sets = (
		'param.negatable.0' => {
			ARGV => ['--no-dice'],
			set => ['!dice' => ['Negatable Flag #1', 'default' => 1]],
			opt_key => 'dice',
			opt_expect => ''
		},
		'param.negatable.0.default' => {
			ARGV => [],
			set => ['!dice' => ['Negatable Flag #1', 'default' => 1]],
			opt_key => 'dice',
			opt_expect => 1
		},
		'param.numeric' => {
			ARGV => ['--param', 123],
			set => ['param=i' => 'Numeric parameter'],
			opt_key => 'param',
			opt_expect => 123
		},
		'param.list.0' => {
			ARGV => ['--param', '', '--param', '-', '--param', 'znark', '--param', 'znark'],
			set => ['param=s@' => 'List parameter'],
			opt_key => 'param',
			opt_expect => ['', '-', 'znark', 'znark']
		},
		'param.list.1' => {
			ARGV => ['-p', 'splort', '-p', 'splort'],
			set => ['p|param=?@' => ['Enumeration', 'values' => ['foo','splort'], 'default' => ['foo']]],
			opt_key => 'param',
			opt_expect => ['splort']
		},
		'param.list.2' => {
			ARGV => ['-p', 'splort', '-p', 'splort'],
			set => ['p|param=?@' => ['Enumeration', 'values' => ['foo','splort'], 'default' => ['foo'], 'keep_unique' => 0]],
			opt_key => 'param',
			opt_expect => ['splort','splort']
		}
	);

	foreach my $key (keys %param_sets) {
		my %options;
		my $set  = $param_sets{$key};
		my $cmdline = __PACKAGE__->new();
		my $mock = Test::MockObject::Extends->new($cmdline);

		$mock->mock(get_option_rules => sub {
			return @{$set->{set} || []};
		});

		local @ARGV = @{$set->{ARGV}};
		$mock->getopt(\%options);
		unless (ref $set->{opt_expect}) {
			is($options{$set->{opt_key}}, $set->{opt_expect}, $key);
		} elsif ('ARRAY' eq ref $set->{opt_expect}) {
			ok(@{$set->{opt_expect}} ~~ @{$options{$set->{opt_key}}}, $key);
		} else {
			fail("$key");
		}
	}
}

# Invalid parameters
{
	my %options;
	my %param_sets = (
		'param.mandatory' => {
			ARGV => ['-f'],
			arg => 'file',
			fmt => 'Option "--%s" requires a value.',
			set => ['f|file=s' => 'Mandatory file']
		},

		'param.invalid.short' => {
			ARGV => ['-T'],
			arg => 'T'
		},

		'param.invalid.negated' => {
			ARGV => ['--no-way-jose'],
			arg => 'way-jose',
			fmt => 'No such option "--no-%s" or negatable "--%s"'
		},

		'param.invalid.long.negated' => {
			ARGV => ['--no-test'], # you wish
			arg => 'test',
			fmt => 'No such option "--no-%s" or negatable "--%s"',
			set => ['t|test' => 'Non-negatable flag']
		},

		'param.invalid.numeric' => {
			ARGV => ['--param', 'abc'],
			arg => 'abc',
			fmt => q{Argument "%s" to "--%s" isn't numeric},
			set => ['param=i' => 'Numeric parameter']
		},

		'param.invalid.enum.0' => {
			ARGV => ['--flag', 'invalid'],
			arg => 'invalid',
			fmt => 'Value "%s" to argument "--%s" is invalid.',
			set => ['flag=?', ['Enumeration', 'values' => ['valid']]]
		},

		'param.invalid.enum.1' => {
			ARGV => ['--flag', 'invalid'],
			arg => 'invalid',
			fmt => 'Value "%s" to argument "--%s" is invalid.',
			set => ['flag=?', ['Enumeration', 'values' => undef]]
		},

		'param.invalid.list' => {
			ARGV => ['--list', undef],
			arg => 'list',
			fmt => 'Option "--%s" requires a value.',
			set => ['list=s@' => 'List parameter']
		},

		'param.context' => {
			ARGV => ['--flag', '--before', '--done'],
			set => [
				'flag' => ['Flag #1', 'context' => '+ctx'],
				'before' => ['Flag #2', 'context' => 'ctx'],
				'done' => ['Flag #3', 'context' => '-ctx'],
			]
		},

		'param.context' => {
			ARGV => ['--not', '--now'],
			set => [
				'now' => ['Now', 'context' => '+ctx'],
				'not' => ['It dieded', 'context' => 'ctx']
			],

			arg => 'not',
			fmt => 'Option "--%s" cannot be used in this context.'
		},

		'code.coverage.2' => {
			ARGV => [],
			set => ['p|param' => 'A parameter', 'p|post' => 'A duplicate short parameter'],
			expect_error => qr/Option spec .+ redefines short option 'p'/
		},

		'code.coverage.3' => {
			ARGV => [],
			set => ['p|param' => 'A parameter', 'P|param' => 'A duplicate long parameter'],
			expect_error => qr/Option spec .+ redefines long option 'param'/
		},

		'code.coverage.4' => {
			ARGV => [],
			set => ['param' => ['Unvalid parameter options', 'are present here.']],
			expect_error => qr/^Invalid rule options/
		}
	);

	foreach my $key (keys %param_sets) {
		my $set  = $param_sets{$key};
		my $cmdline = __PACKAGE__->new();
		my $mock = Test::MockObject::Extends->new($cmdline);

		$mock->mock(get_option_rules => sub {
			return @{$set->{set} || []};
		});
		$mock->mock(error => sub {
			my ($self, $fmt, $arg) = @_;

			is($arg, $set->{arg}, "$key.0");
			is($fmt, $set->{fmt}, "$key.1") if exists $set->{fmt};
			die $self;
		});

		local @ARGV = @{$set->{ARGV}};
		eval {$mock->getopt(\%options);1} and next;
		my $error = $@;
		if (blessed($error) && $mock == $error) {
		} elsif (!exists $set->{expect_error}) {
			die $error;
		} else {
			ok("$error" ~~ $set->{expect_error}, $key) || diag($error);
		}
	}
}
