package Form::Tiny::Plugin::MyMetaRolePlugin;

use strict;
use warnings;

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		meta_roles => [__PACKAGE__],
	};
}

use Moo::Role;

sub some_method { 77 }

1;
