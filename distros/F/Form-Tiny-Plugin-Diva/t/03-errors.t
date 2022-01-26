use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestForm;

my $form = TestForm->new(fails => 1);

subtest 'test diva errors' => sub {
	my %input = (
		shown => '--shown-value--',
		shown_no_label => '--shown-no-label-value--',
	);

	$form->set_input(\%input);
	ok !$form->valid;

	my $data = $form->diva->generate;
	like $data->[0]{errors}, qr{--text-must-be-short--}, 'error ok';
	like $data->[0]{errors}, qr{--text-must-be-very-short--}, 'error ok';
	is $data->[1]{errors}, '', 'error ok';

	like $form->diva->form_errors, qr{--global-error--}, 'global error ok';

	is_deeply $form->diva->prefill, $data, 'prefill works the same as generate with errors';
};

done_testing;
