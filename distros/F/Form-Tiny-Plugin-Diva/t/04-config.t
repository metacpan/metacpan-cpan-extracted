use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFormConfigured;

my $form = TestFormConfigured->new;

subtest 'test diva config' => sub {
	my %input = (
		shown => '--shown-value--',
	);

	$form->set_input(\%input);
	ok !$form->valid;

	my $data = $form->diva->generate;
	like $data->[0]{label}, qr{mylabel-class}, 'label class ok';
	like $data->[0]{input}, qr{id=.myident-shown}, 'identifier ok';
	like $data->[0]{errors}, qr{myerror-class}, 'error ok';

	is_deeply $form->diva->prefill, $data, 'prefill works the same as generate with config';
};

done_testing;
