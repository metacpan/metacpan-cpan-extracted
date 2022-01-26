package Form::Tiny::Plugin::Diva::MetaRole;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.01';

use Moo::Role;

use constant DEFAULT_CONFIG => {
	id_base => 'form-field-',
	label_class => 'form-label',
	input_class => 'form-control',
	error_class => 'invalid-feedback',
};

has '_diva_config' => (
	is => 'ro',
	writer => 'set_diva_config',
	default => sub { {} },
);

sub diva_config
{
	my ($self) = @_;

	return {
		%{+DEFAULT_CONFIG},
		%{$self->_diva_config},
	};
}

sub add_diva_config
{
	my ($self, %config) = @_;

	for my $key (keys %config) {
		$self->_diva_config->{$key} = $config{$key};
	}

	return;
}

after 'inherit_from' => sub {
	my ($self, $parent) = @_;

	if ($parent->DOES('Form::Tiny::Plugin::Diva::MetaRole')) {
		$self->set_diva_config({%{$parent->_diva_config}, %{$self->_diva_config}});
	}
};

1;

