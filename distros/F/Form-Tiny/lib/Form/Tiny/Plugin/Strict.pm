package Form::Tiny::Plugin::Strict;
$Form::Tiny::Plugin::Strict::VERSION = '2.26';
use v5.10;
use strict;
use warnings;

use Form::Tiny::Error;
use Form::Tiny::Path;

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		meta_roles => [__PACKAGE__],
	};
}

use Moo::Role;

requires qw(setup);

# cache for the blueprint (if non-dynamic)
has '_strict_blueprint' => (
	is => 'rw',
);

sub _check_recursive
{
	my ($self, $data, $blueprint) = @_;
	return [{path => Form::Tiny::Path->empty, error => 'unexpected'}]
		unless defined $blueprint;

	if (ref $blueprint eq 'ARRAY') {
		return [{path => Form::Tiny::Path->empty, error => 'not an array'}]
			unless ref $data eq 'ARRAY';

		my @errors;
		foreach my $key (0 .. $#$data) {
			my $err = $self->_check_recursive($data->[$key], $blueprint->[0]);
			push @errors, map {
				$_->{path}->prepend(ARRAY => $key);
				$_;
			} @$err;
		}

		return \@errors;
	}
	elsif (ref $blueprint eq 'HASH') {
		return [{path => Form::Tiny::Path->empty, error => 'not an object'}]
			unless ref $data eq 'HASH';

		my @errors;
		for my $key (keys %$data) {
			my $err = $self->_check_recursive($data->{$key}, $blueprint->{$key});
			push @errors, map {
				$_->{path}->prepend(HASH => $key);
				$_;
			} @$err;
		}

		return \@errors;
	}
	else {
		# we're at leaf and no error occured - we're good.
	}

	return [];
}

sub _check_strict
{
	my ($self, $obj, $input) = @_;

	my $blueprint = $self->_strict_blueprint;
	if (!$blueprint) {
		$blueprint = $self->blueprint($obj, recurse => 0);
		$self->_strict_blueprint($blueprint)
			unless $self->is_dynamic;
	}

	my @unexpected_field;
	my $errors = $self->_check_recursive($input, $blueprint, \@unexpected_field);
	foreach my $err (@$errors) {
		$obj->add_error(
			$self->build_error(
				'IsntStrict',
				extra_field => $err->{path}->join,
				error => $err->{error},
			)
		);
	}

	return $input;
}

after 'setup' => sub {
	my ($self) = @_;

	$self->add_hook(
		Form::Tiny::Hook->new(
			hook => 'before_validate',
			code => sub { $self->_check_strict(@_) },
			inherited => 0,
		)
	);
};

1;

