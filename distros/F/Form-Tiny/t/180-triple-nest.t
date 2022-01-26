use v5.10;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Form::Tiny::Inline;

my $form = Form::Tiny::Inline->is(qw(Strict))->new(
	field_defs => [{name => "one.two.three"}],
	input => {one => {two => {three => 3}}},
);

ok($form->valid, "validation ok");
is($form->fields->{one}{two}{three}, 3, "value ok");

$form->set_input({one => {two => 2}});

ok(!$form->valid, "invalid form validation ok");

done_testing;
