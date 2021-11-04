use v5.10;
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

{

	package TestForm;
	use Form::Tiny;

	form_field 'testS';
	form_field 'testA.*';
	form_field 'testH.test';
}

for (qw(regular dcloned)) {
	my @data = (
		[{testS => 5}, sub { shift->{testS} = 4; }, {testS => 5}],
		[{testS => [1, 2]}, sub { push @{shift->{testS}}, 3 }, {testS => [1, 2, 3]}],
		[{testS => {key => 'yes'}}, sub { shift->{testS}{key} = 'no' }, {testS => {key => 'no'}}],
		[{testA => [1, 2]}, sub { push @{shift->{testA}}, 3 }, {testA => [1, 2]}],
		[{testA => [[1]]}, sub { push @{shift->{testA}[0]}, 2 }, {testA => [[1, 2]]}],
		[{testH => {test => 'yes'}}, sub { shift->{testH}{test} = 'no' }, {testH => {test => 'yes'}}],
		[
			{testH => {test => {key => 'yes'}}},
			sub { shift->{testH}{test}{key} = 'no' },
			{testH => {test => {key => 'no'}}}
		],
	);

	my $form = TestForm->new;

	if (/dcloned/) {
		$form->form_meta->add_hook(reformat => sub { shift; dclone(shift) });
		$_->[2] = dclone($_->[0]) for @data;
	}

	for my $aref (@data) {
		my $input = $aref->[0];
		$form->set_input($input);
		ok $form->valid, "no error detected";

		my $fields = $form->fields;
		$aref->[1]->($fields);

		is_deeply $input, $aref->[2], "cloning behavior ok";
	}
}

done_testing();
