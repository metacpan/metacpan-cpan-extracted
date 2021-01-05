use v5.10;
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
	[0, {nested => "not really"}],
	[0, {nested => {second => 1}}],
	[0, {nested_form => {int => 5, nothere => 1}}],
	[0, {int => 3, arg2 => 15}],
	[0, {arg2 => "more data"}],
	[0, {not => {nested => "more data"}}],
);

for my $aref (@data) {
	my ($result, $input) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	if ($form->valid && $result) {
		is_deeply($form->fields, $input, "fields do match");
	}
	elsif (!$result) {
		for (@{$form->errors}) {
			isa_ok($_, "Form::Tiny::Error::IsntStrict");
		}
		note Dumper($form->errors) if @{$form->errors} > 1;
	}
	else {
		note Dumper($form->errors);
	}
}

done_testing();
