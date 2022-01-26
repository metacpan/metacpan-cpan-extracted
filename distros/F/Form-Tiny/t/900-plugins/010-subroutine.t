use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';

{

	package My::Form;

	use Form::Tiny plugins => ['MyPlugin'];

	test_caller __PACKAGE__;

	test_no_context;

	form_field 'abc';

	test_context 'abc';

	form_cleaner sub {
	};

	test_no_context;

	test_add_context 'not_in_form';

	test_context 'not_in_form';
}

done_testing 5;
