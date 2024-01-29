package Form::Tiny::Plugin::Strict;
$Form::Tiny::Plugin::Strict::VERSION = '2.23';
use v5.10;
use strict;
use warnings;

use Form::Tiny::Error;

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
	return 0 unless defined $blueprint;

	my $ref = ref $blueprint;

	if ($ref eq 'ARRAY') {
		return 0 unless ref $data eq 'ARRAY';

		foreach my $value (@$data) {
			return 0
				unless $self->_check_recursive($value, $blueprint->[0]);
		}
	}
	elsif ($ref eq 'HASH') {
		return 0 unless ref $data eq 'HASH';

		for my $key (keys %$data) {
			return 0
				unless $self->_check_recursive($data->{$key}, $blueprint->{$key});
		}
	}
	else {
		# we're at leaf and no error occured - we're good.
	}

	return 1;
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

	my $strict = $self->_check_recursive($input, $blueprint);
	if (!$strict) {
		$obj->add_error($self->build_error(IsntStrict =>));
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

