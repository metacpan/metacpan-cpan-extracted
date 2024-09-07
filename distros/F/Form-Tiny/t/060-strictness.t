use v5.10;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use lib 't/lib';
use TestForm;

my @data = (
	[1, {}],
	[1, {no_type => "test"}],
	[1, {nested => {name => 1}}],
	[1, {nested => {second => {name => 1}}}],
	[1, {nested_form => {optional => "yes", int => 1}}],
	[0, {nested => "not really"}, 'general - nested: not an object'],
	[0, {nested => ["not really"]}, 'general - nested: not an object'],
	[0, {nested => {second => 1}}, 'general - nested.second: not an object'],
	[0, {nested_form => {int => 5, nothere => 1}}, 'nested_form - nothere: unexpected'],
	[0, {int => 3, arg2 => 15}, 'general - arg2: unexpected'],
	[0, {arg2 => "more data"}, 'general - arg2: unexpected'],
	[0, {not => {nested => "more data"}}, 'general - not.nested: unexpected'],
	[0, {array => [{}, {value => 'x'}]}, 'general - array.1.value: unexpected'],
	[0, {not => {'*' => {test => 1}}}, 'general - not.\\*.test: unexpected'],
	[0, {'is\\' => {test => 1}}, 'general - is\\\\.test: unexpected'],
);

for my $aref (@data) {
	my ($result, $input, $error) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	if ($form->valid && $result) {
		is_deeply($form->fields, $input, "fields do match");
	}
	elsif (!$result) {
		is scalar @{$form->errors}, 1, 'error count ok';
		isa_ok($form->errors->[0], "Form::Tiny::Error::IsntStrict");
		is '' . $form->errors->[0], $error, 'error string ok';
	}
	else {
		note Dumper($form->errors);
	}
}

done_testing();

