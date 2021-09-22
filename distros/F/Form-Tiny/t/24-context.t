use v5.10;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny;
	use Test::More;
	use Test::Exception;


	my $meta = __PACKAGE__->form_meta;
	# without context, we should not be able to use context DSL
	dies_ok {
		field_validator 'test' => sub {};
	};

	form_field 'context1';
	lives_and {
		field_validator 'test1' => sub {};
		is $meta->fields->[-1]->addons->{validators}[-1][0], 'test1', 'validator message ok';
	};

	# context should reset if we use another DSL
	form_hook cleanup => sub {};
	dies_ok {
		field_validator 'test2' => sub {};
	};

	form_field 'context2';
	lives_and {
		field_validator 'test3' => sub {};
		is $meta->fields->[-1]->addons->{validators}[-1][0], 'test3', 'validator message ok';

		field_validator 'test4' => sub {};
		is $meta->fields->[-1]->addons->{validators}[-1][0], 'test4', 'validator message ok';
	};
}

done_testing();
