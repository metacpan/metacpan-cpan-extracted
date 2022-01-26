package Form::Tiny::Plugin::MyPlugin;

use strict;
use warnings;
use Test::More;
use Form::Tiny::FieldDefinition;

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		subs => {
			test_caller => sub {
				is $caller, shift, 'caller ok';
			},
			test_context => sub {
				is $$context->name, shift, 'context ok';
			},
			test_no_context => sub {
				ok !defined $$context, 'no context ok';
			},
			test_add_context => sub {
				$$context = Form::Tiny::FieldDefinition->new(name => shift);
			},
		},
	};
}

1;
