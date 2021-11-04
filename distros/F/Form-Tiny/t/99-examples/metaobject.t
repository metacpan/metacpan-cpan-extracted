use v5.10;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use ExampleHelpers;

lives_and {
	my $form = do_example 'metaobject';

	ok($form->valid, "no DSL form works");
};

done_testing();
