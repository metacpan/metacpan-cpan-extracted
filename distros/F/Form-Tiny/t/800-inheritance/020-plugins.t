use v5.10;
use strict;
use warnings;
use Test::More;
use lib 't/lib';

{

	package PluginInheritanceParentForm;

	use Form::Tiny plugins => ['MyRolePlugin', 'MyMetaRolePlugin'];
	__PACKAGE__->form_meta;
}

{

	package PluginInheritanceChildForm;

	use Form::Tiny;
	extends 'PluginInheritanceParentForm';
	__PACKAGE__->form_meta;
}

{

	package PluginInheritanceGrandchildForm;

	use Form::Tiny -filtered;
	extends 'PluginInheritanceChildForm';
	__PACKAGE__->form_meta;
}

subtest 'test child plugin class' => sub {
	ok(PluginInheritanceChildForm->form_meta->DOES('Form::Tiny::Plugin::MyMetaRolePlugin'), 'meta role plugin ok');
	ok(PluginInheritanceChildForm->DOES('Form::Tiny::Plugin::MyRolePlugin'), 'role plugin ok');
};

subtest 'test grandchild plugin class' => sub {
	ok(
		PluginInheritanceGrandchildForm->form_meta->DOES('Form::Tiny::Plugin::MyMetaRolePlugin'),
		'meta role plugin ok'
	);
	ok(
		PluginInheritanceGrandchildForm->form_meta->DOES('Form::Tiny::Meta::Filtered'),
		'filtered meta role plugin ok'
	);
	ok(PluginInheritanceGrandchildForm->DOES('Form::Tiny::Plugin::MyRolePlugin'), 'role plugin ok');
};

done_testing;

