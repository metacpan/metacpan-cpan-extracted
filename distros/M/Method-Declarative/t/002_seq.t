#!/usr/bin/perl

# t/002_seq.t - Test sequence of operations

use Test::More tests => 8;

BEGIN { $Foo::init_count = 0; }

use Method::Declarative
(
	'--defaults' =>
	{
		package => 'Foo',
	},
	new =>
	{
		code => sub { return bless { ctr => 0 }, (ref $_[0]||$_[0]); },
	},
	'method1' =>
	{
		init =>
		[
			[
				sub
				{
					ok(0==$Foo::init_count);
					$Foo::init_count++;
				},
			],
		],
		end =>
		[
			[
				sub
				{
					ok(2==$Foo::init_count);
					$Foo::init_count++;
				},
			],
		],
		precheck =>
		[
			[
				sub
				{
					my ($self, $name, $issc, $ar, $arg)
						= @_;
					ok($arg==$self->{ctr});
					$self->{ctr}++;
					@$ar;
				},
				0,
			],
		],
		code =>
		sub
		{
			my ($self) = @_;
			ok($self->{ctr} == 1);
			$self->{ctr}++;
			$self->{ctr};
		},
		postcheck =>
		[
			[
				sub
				{
					my ($self, $name, $issc, $res, $arg)
						= @_;
					ok($arg==$self->{ctr});
					$self->{ctr}++;
					@$res;
				},
				2,
			],
		],
	},
	'DESTROY' =>
	{
		code =>
		sub
		{
			my ($self) = @_;
			return unless ref $self and $self->{ctr};
			ok(3==$self->{ctr});
		},
		init =>
		[
			[
				sub
				{
					ok(1==$Foo::init_count);
					$Foo::init_count++;
				},
			],
		],
		end =>
		[
			[
				sub
				{
					ok(3==$Foo::init_count);
					$Foo::init_count++;
				},
			],
		],
	}
) ;

my $foo = new Foo;
$foo->method1();
