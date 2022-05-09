use v5.10;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use lib 't/lib';
use TestForm;

sub fdef
{
	my ($name, $class) = @_;
	$class //= 'TestForm';

	for my $def (@{$class->form_meta->fields}) {
		return $def if $def->name eq $name;
	}

	die "Unknown field name: $name";
}

sub fdef_inner
{
	return fdef(shift, 'TestInnerForm');
}

my $expected = {
	no_type => fdef('no_type'),
	sub_coerced => fdef('sub_coerced'),
	int => fdef('int'),
	int_coerced => fdef('int_coerced'),
	str => fdef('str'),
	str_adjusted => fdef('str_adjusted'),
	bool_cleaned => fdef('bool_cleaned'),
	nested => {
		name => fdef('nested.name'),
		second => {
			name => fdef('nested.second.name'),
		},
	},
	'not.nested' => fdef('not\\.nested'),
	'is\\' => {
		nested => fdef('is\\\\.nested'),
	},
	'not\\.nested' => fdef('not\\\\\\.nested'),
	'not' => {
		'*' => {
			nested_array => fdef('not.\\*.nested_array'),
		},
	},
	nested_form => {
		optional => fdef_inner('optional'),
		int => fdef_inner('int'),
	},
	nested_form_unadjusted => {
		optional => fdef_inner('optional'),
		int => fdef_inner('int'),
	},
	array => [
		{
			name => fdef('array.*.name'),
			second => [
				{
					name => fdef('array.*.second.*.name'),
				}
			],
		}
	],
	marray => [
		[
			fdef('marray.*.*')
		]
	],
};

is_deeply(TestForm->form_meta->blueprint, $expected, 'blueprint structure ok');
note Dumper(TestForm->form_meta->blueprint);

done_testing;

