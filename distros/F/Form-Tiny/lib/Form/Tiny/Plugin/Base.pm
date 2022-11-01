package Form::Tiny::Plugin::Base;
$Form::Tiny::Plugin::Base::VERSION = '2.15';
use v5.10;
use strict;
use warnings;

use parent 'Form::Tiny::Plugin';

# This plugin is the core of Form::Tiny DSL

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		subs => {
			form_field => sub {
				$$context = $caller->form_meta->add_field(@_);
			},
			form_cleaner => sub {
				$$context = undef;
				$caller->form_meta->add_hook(cleanup => @_);
			},
			form_hook => sub {
				$$context = undef;
				$caller->form_meta->add_hook(@_);
			},
			field_validator => sub {
				$caller->form_meta->add_field_validator($self->use_context($context), @_);
			},
			form_message => sub {
				$$context = undef;
				my %params = @_;
				for my $key (keys %params) {
					$caller->form_meta->add_message($key, $params{$key});
				}
			},
		},

		roles => ['Form::Tiny::Form'],
	};
}

1;

