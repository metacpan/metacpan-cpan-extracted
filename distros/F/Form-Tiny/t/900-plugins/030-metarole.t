use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';

{

	package My::Form;

	use Form::Tiny plugins => ['MyMetaRolePlugin', '+Form::Tiny::Plugin::MyRolePlugin'], -strict;

	form_field 'abc';
}

ok(My::Form->DOES('Form::Tiny::Plugin::MyRolePlugin'), 'role composed');
ok(My::Form->form_meta->DOES('Form::Tiny::Plugin::MyMetaRolePlugin'), 'meta role composed');
ok(My::Form->form_meta->DOES('Form::Tiny::Plugin::Strict'), 'strict meta role still composed');
ok(My::Form->form_meta->can('some_method'), 'meta method composed');

done_testing;

