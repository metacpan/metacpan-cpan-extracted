use v5.10;
use strict;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -filtered;
	use Types::Standard qw(Str Int);

	use Form::Tiny::Filter;
	use Form::Tiny::Plugin::Filtered::Filter;

	form_field 'f1';
	field_filter Str, sub { pop() . '+' };
	field_filter Str, sub { pop() . '-' };

	form_field 'f2';

	form_filter Int, sub { pop() . '!' };

	form_field 'f3';

	# use classes (deprecated)
	field_filter (Form::Tiny::Filter->new(
		type => Str,
		code => sub { pop() . '+' }
	));

	# use classes (current)
	field_filter (Form::Tiny::Plugin::Filtered::Filter->new(
		type => Str,
		code => sub { pop() . '-' }
	));
}

my @data = (
	[{f1 => 5}, {f1 => '5!+-'}],
	[{f1 => 'aa'}, {f1 => 'aa+-'}],
	[{f2 => 5}, {f2 => '5!'}],
	[{f3 => 5}, {f3 => '5!+-'}],
	[{f3 => 'aa'}, {f3 => 'aa+-'}],
);

my $form = TestForm->new;
for my $aref (@data) {
	$form->set_input($aref->[0]);
	ok $form->valid, "no error detected";
	is_deeply $form->fields, $aref->[1], "value correctly filtered";
}

done_testing();

