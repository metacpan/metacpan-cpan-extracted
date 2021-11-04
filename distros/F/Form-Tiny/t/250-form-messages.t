use v5.10;
use strict;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -strict;
	use Test::More;
	use Test::Exception;

	form_message
		Required => 'reqmsg',
		InvalidFormat => 'invformsg',
		IsntStrict => 'strictmsg';

	dies_ok {
		form_message Requried => 'typo in name';
	} 'typo dies ok';

	note $@;

	form_field 'required' => (
		required => 1
	);
}

my $form = TestForm->new;

subtest 'testing required message' => sub {
	$form->set_input({});

	ok !$form->valid, 'validation failed ok';
	is_deeply $form->errors_hash, {
		'required' => ['reqmsg']
		},
		'errors ok';
};

subtest 'testing invalid format message' => sub {
	$form->set_input([]);

	ok !$form->valid, 'validation failed ok';
	is_deeply $form->errors_hash, {
		'' => ['invformsg']
		},
		'errors ok';
};

subtest 'testing strict message' => sub {
	$form->set_input({required => 1, loose => 1});

	ok !$form->valid, 'validation failed ok';
	is_deeply $form->errors_hash, {
		'' => ['strictmsg']
		},
		'errors ok';
};

done_testing();
