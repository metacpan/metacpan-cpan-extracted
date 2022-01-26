use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFormWithDefaults;

my $form = TestFormWithDefaults->new;

subtest 'test empty diva defaults' => sub {
	my $data = $form->diva->generate;
	my $hidden = $form->diva->hidden;

	like $data->[0]{input}, qr{value=.shown-default}, 'correct default generated';
	like $data->[1]{input}, qr{value=.shown-default-good}, 'correct default generated';
	like $hidden, qr{value=.not-shown-default}, 'correct hidden default generated';

	is_deeply $form->diva->prefill, $form->diva->generate, 'prefill works';
};

subtest 'test filled defaults' => sub {
	my %input = (
		shown_default => 'not-a-default',
		not_shown => 'not-a-hidden-default',
	);

	$form->set_input(\%input);
	my $data = $form->diva->generate;
	my $hidden = $form->diva->hidden;
	my $prefill = $form->diva->prefill;

	like $data->[0]{input}, qr{value=.$input{shown_default}}, 'default not used';
	like $data->[1]{input}, qr{value=(.)\1}, 'default not generated';
	like $hidden, qr{value=.$input{not_shown}}, 'correct hidden default generated';

	like $prefill->[0]{input}, qr{value=.$input{shown_default}}, 'default not used in prefill';
	like $prefill->[1]{input}, qr{value=.shown-default-good}, 'correct default generated';
};

done_testing;
