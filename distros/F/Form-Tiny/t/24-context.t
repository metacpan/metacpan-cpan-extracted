use v5.10;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -filtered;
	use Test::More;
	use Test::Exception;
	use Types::Standard qw(Int);


	my $meta = __PACKAGE__->form_meta;
	# without context, we should be only able to use
	# field_filter with three arguments
	dies_ok {
		field_filter Int, sub {};
	};

	lives_and {
		# TODO: verify if a field exists?
		field_filter test => Int, sub {};
		is @{$meta->filters}, 1, 'filter added ok';
		is $meta->filters->[-1]->field, 'test', 'filter field ok';
	};

	form_field 'context1';
	lives_and {
		field_filter Int, sub {};
		is @{$meta->filters}, 2, 'filter added ok';
		is $meta->filters->[-1]->field, 'context1', 'filter field ok';
	};

	# context should reset if we use another DSL
	form_trim_strings;
	dies_ok {
		field_filter Int, sub {};
	};

	form_field 'context2';
	lives_and {
		field_filter Int, sub {};
		is @{$meta->filters}, 4, 'filter added ok';
		is $meta->filters->[-1]->field, 'context2', 'filter field ok';

		field_filter Int, sub {};
		is @{$meta->filters}, 5, 'filter added ok';
		is $meta->filters->[-1]->field, 'context2', 'filter field ok';
	};

	# context should reset if a field does not have explicit name
	form_field sub { { name => 'context3' } };
	dies_ok {
		field_filter Int, sub {};
	};
}

done_testing();
