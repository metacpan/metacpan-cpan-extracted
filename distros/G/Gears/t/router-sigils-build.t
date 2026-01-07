use v5.40;
use Test2::V1 -ipP;

use lib 't/lib';
use Gears::Test::Router;

################################################################################
# This tests whether the sigil-based router building works
################################################################################

my $r = Gears::Test::Router->new(
	location_impl => 'Gears::Router::Location::SigilMatch',
);

subtest 'checks should be honored during location building' => sub {
	my $l = $r->clear->add('/:num' => {checks => {num => '\d'}});

	like dies { $l->build() }, qr/no value for placeholder :num/, 'missing ok';
	like dies { $l->build(num => 'a') }, qr/bad value for placeholder :num/, 'non-numeric ok';
	like dies { $l->build(num => '42') }, qr/bad value for placeholder :num/, 'double digit ok';
};

_build(
	'no placeholders',
	'/bar',
	{},
	'/bar',
);

_build(
	'one placeholder',
	'/:test',
	{test => 42},
	'/42',
);

_build(
	'one optional placeholder with default',
	'/?test',
	{},
	'/42',
	defaults => {test => 42},
);

_build(
	'two placeholders, one optional, no argument and no default',
	'/:abc/?def',
	{abc => 5},
	'/5',
);

_build(
	'one optional placeholder at start, no default',
	'/?test/abc',
	{},
	'/abc',
);

_build(
	'bracketed slurpy placeholder inside text with a default',
	'/abc{>def}ghi',
	{},
	'/abcjklghi',
	defaults => {def => 'jkl'},
);

_build(
	'bracketed slurpy placeholder after a slash',
	'/abc/{>def}',
	{},
	'/abc/',
);

done_testing;

sub _build ($name, $pattern, $params, $expected, %args)
{
	my $l = $r->clear->add($pattern, \%args);

	subtest "should pass case: $name" => sub {
		is $l->build($params->%*), $expected, 'building ok';
	};
}

