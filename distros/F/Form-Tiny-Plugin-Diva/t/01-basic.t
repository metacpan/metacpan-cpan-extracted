use v5.10;
use strict;
use warnings;
use Test::More;
use Form::Diva;

use lib 't/lib';
use TestForm;

my $form = TestForm->new;
can_ok $form, 'diva';

subtest 'test empty diva' => sub {
	my $data = $form->diva->generate;
	is scalar @$data, 2, 'field with no data section not returned';

	like $data->[0]{label}, qr{>Shown</label>}i, 'correct label generated';
	like $data->[0]{input}, qr{name=.shown}, 'correct name generated';
	like $data->[0]{input}, qr{type=.text}, 'correct type generated';

	is $data->[1]{label}, '', 'correct label generated';
	like $data->[1]{input}, qr{name=.shown_no_label.}, 'correct name generated';
	like $data->[1]{input}, qr{type=.email}, 'correct type generated';

	is_deeply $form->diva->prefill, $data, 'prefill works';

	my $hidden = $form->diva->hidden;
	like $hidden, qr{name=.not_shown}, 'hidden has field 1';
	like $hidden, qr{name=.manual_hidden}, 'hidden has field 2';
};

subtest 'test filled diva' => sub {
	my %input = (
		shown => '--shown-value--',
		shown_no_label => '--shown-no-label-value--',
		not_shown => '--not-shown-value--',
		manual_hidden => '--manual-hidden-value--',
	);

	$form->set_input(\%input);
	my $data = $form->diva->generate;
	like $data->[0]{input}, qr{value=.$input{shown}}, 'field value included';
	like $data->[1]{input}, qr{value=.$input{shown_no_label}}, 'field value included';

	is_deeply $form->diva->prefill, $data, 'prefill works';

	my $hidden = $form->diva->hidden;
	like $hidden, qr{value=.$input{not_shown}}, 'hidden field value included';
	like $hidden, qr{value=.$input{manual_hidden}}, 'manual hidden field value included';
};

subtest 'test diva datavalues' => sub {
	my $wanted = [
		{
			id => 'form-field-shown',
			name => 'shown',
			type => 'text',
			label => 'Shown',
			value => '--shown-value--',
		},
		{
			id => 'form-field-shown_no_label',
			name => 'shown_no_label',
			type => 'email',
			label => Form::Diva->VERSION >= 1.04 ? '' : 'Shown_no_label',
			value => '--shown-no-label-value--',
		}
	];

	# we no need no comment
	my $values = $form->diva->datavalues;
	delete $_->{comment} for (@$values);

	is_deeply $values, $wanted, 'data values ok';

	my $morevalues = $form->diva->datavalues('moredata');
	ok exists $morevalues->[0]{class}, 'additional parameters to datavalues are honored';
};

done_testing;

