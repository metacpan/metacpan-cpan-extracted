use v5.10;
use warnings;
use Test::More;

BEGIN { use_ok('Form::Tiny::Inline') }

my $form = Form::Tiny::Inline->is(qw(Filtered Strict))->new(
	field_defs => [{name => "test"}],
	input => {test => "   asd "},
);

ok($form->valid, "still strict");
is($form->fields->{test}, "asd", "Str filtered");

$form->set_input({%{$form->input}, more => 1});

ok(!$form->valid, "not strict anymore");

done_testing();
