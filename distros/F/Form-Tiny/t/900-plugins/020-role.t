use v5.10;
use strict;
use warnings;
use Test::More;

use lib 't/lib';

{

	package My::Form;

	use Form::Tiny plugins => ['MyPlugin', 'MyRolePlugin'], -filtered;

	form_trim_strings;

	test_caller __PACKAGE__;

	form_field 'abc';
}

ok(My::Form->DOES('Form::Tiny::Form'), 'Form role still composed');
ok(My::Form->DOES('Form::Tiny::Plugin::MyRolePlugin'), 'role composed');
ok(My::Form->can('some_method'), 'method composed');
ok(!My::Form->can('plugin'), 'plugin method not composed');

done_testing;
