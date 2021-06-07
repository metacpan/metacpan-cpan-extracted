use v5.10;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use ExampleHelpers;

lives_and {
	my $form = do_example 'inline_form';

	ok($form->valid, "The form has been validated successfully");
};

done_testing();
