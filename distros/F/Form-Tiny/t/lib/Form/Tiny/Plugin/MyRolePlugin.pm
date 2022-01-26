package Form::Tiny::Plugin::MyRolePlugin;

use strict;
use warnings;

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		roles => [__PACKAGE__],
	};
}

use Moo::Role;

sub some_method { 77 }

1;
