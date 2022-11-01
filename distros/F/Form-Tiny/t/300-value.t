use v5.10;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use TestForm;

my $form = TestForm->new;
my %data = (
	str => 'single value',
	no_type => 5,
	nested => {
		name => 'nested 1',
		second => {
			name => 'nested 2'
		},
	},
	array => [
		{
			name => 'array 1 1',
			second => [
				{
					name => 'array 2 1 1',
				},
				{
					name => 'array 2 1 2',
				}
			],
		},
		{
			name => 'array 1 2',
			second => [
				{
					name => 'array 2 2 1',
				}
			],
		}
	],
	marray => [
		[
			11,
			22,
		],
		[
			33,
		],
		[
			44,
			55,
		],
	]
);

$form->set_input(\%data);

subtest 'should return undef before validation' => sub {
	ok !defined $form->value('str'), 'value ok';
	ok !defined $form->value('marray.*.*'), 'value ok';
};

ok $form->valid, 'validation ok';

subtest 'should return existing single flat field value' => sub {
	is $form->value('str'), $data{str}, 'value 1 ok';
	is $form->value('no_type'), $data{no_type}, 'value 2 ok';
};

subtest 'should die on non-existing field name' => sub {
	dies_ok {
		$form->value('')
	} 'exception 1 ok';

	dies_ok {
		$form->value('str2')
	} 'exception 2 ok';

	dies_ok {
		$form->value('NO_TYPE')
	} 'exception 3 ok';

	dies_ok {
		$form->value('nested\.name')
	} 'exception 4 ok';

	dies_ok {
		$form->value('nested.names')
	} 'exception 5 ok';
};

subtest 'should return existing single nested field value' => sub {
	is $form->value('nested.name'), $data{nested}{name}, 'value 1 ok';
	is $form->value('nested.second.name'), $data{nested}{second}{name}, 'value 2 ok';
};

subtest 'should return existing multi field value' => sub {
	is_deeply $form->value('array.*.name'), ['array 1 1', 'array 1 2'], 'value 1 ok';
	is_deeply $form->value('array.*.second.*.name'), ['array 2 1 1', 'array 2 1 2', 'array 2 2 1'], 'value 2 ok';
};

subtest 'should return existing multi field value (array of array)' => sub {
	is_deeply $form->value('marray.*.*'), [11, 22, 33, 44, 55], 'value 1 ok';
};

done_testing();

