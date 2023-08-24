use v5.10;
use strict;
use warnings;
use Test::More;

{

	package Form::Nested;

	use Form::Tiny;
	use Types::Standard qw(Int Str);

	form_field 'value1' => (
		type => Int,
		adjust => sub { abs pop },
	);

	form_field 'comments.*' => (
		type => Str,
	);
}

{

	package Form::Parent;

	use Form::Tiny;

	form_field 'subform.*' => (
		type => Form::Nested->new,
	);
}

my $form = Form::Parent->new;

subtest 'should validate and adjust' => sub {
	$form->set_input(
		{
			subform => [
				{
					value1 => 1,
				},
				{
					value1 => -2,
					comments => ['negative value'],
				},
			],
		}
	);

	ok $form->valid, 'form valid ok';
	is_deeply $form->fields, {
		subform => [
			{
				value1 => 1,
			},
			{
				value1 => 2,
				comments => ['negative value'],
			},
		],
	};
};

subtest 'should properly join error fields' => sub {
	$form->set_input(
		{
			subform => [
				{
					value1 => 1,
					comments => [\'negative value'],
				},
			],
		}
	);

	ok !$form->valid, 'form not valid ok';
	is scalar @{$form->errors}, 1, 'error count ok';
	is $form->errors->[0]->field, 'subform.*.comments.*', 'error field ok';
};

done_testing;

