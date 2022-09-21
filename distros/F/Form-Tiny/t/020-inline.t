use v5.10;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Form::Tiny::Inline') }

subtest 'legacy inline form' => sub {
	my $form = Form::Tiny::Inline->is(qw(Filtered Strict))->new(
		field_defs => [{name => "test"}],
		input => {test => "   asd "},
	);

	ok($form->valid, "still strict");
	is($form->fields->{test}, "asd", "Str filtered");

	$form->set_input({%{$form->input}, more => 1});

	ok(!$form->valid, "not strict anymore");
};

subtest 'inline form' => sub {
	my $form = Form::Tiny::Inline->is(qw(Filtered))->new(
		fields => {test => {}},
		input => {test => "   asd "},
	);

	ok($form->valid, 'form is valid');
	is($form->fields->{test}, "asd", "Str filtered");
};

done_testing;

