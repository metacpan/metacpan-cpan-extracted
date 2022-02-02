package Form::Tiny::Meta::Strict;

use v5.10;
use strict;
use warnings;

use Form::Tiny::Utils qw(try);
use Form::Tiny::Error;

use Moo::Role;

our $VERSION = '2.09';

use constant {
	MARKER_NONE => '',
	MARKER_SKIP => 'skip',
	MARKER_ARRAY => 'array',
	MARKER_LEAF => 'leaf',
};

requires qw(setup);

sub _check_recursive
{
	my ($self, $obj, $data, $markers, $path) = @_;
	$path //= Form::Tiny::Path->empty;

	my $current_path = $path->join;
	my $metadata = $markers->{$current_path} // MARKER_NONE;

	return if $metadata eq MARKER_SKIP;

	if ($metadata eq MARKER_LEAF) {

		# we're at leaf and no error occured - we're good.
	}

	elsif ($metadata eq MARKER_ARRAY) {
		die $current_path unless ref $data eq 'ARRAY';
		foreach my $value (@$data) {
			$self->_check_recursive(
				$obj, $value, $markers,
				$path->clone->append('ARRAY')
			);
		}
	}

	else {
		# only leaves are allowed to be anything
		# on regular elements we expect a hashref
		die $current_path unless ref $data eq 'HASH';
		for my $key (keys %$data) {
			$self->_check_recursive(
				$obj, $data->{$key}, $markers,
				$path->clone->append(HASH => $key)
			);
		}
	}
}

sub _check_strict
{
	my ($self, $obj, $input) = @_;

	my %markers;
	foreach my $def (@{$obj->field_defs}) {
		if ($def->is_subform) {
			$markers{$def->name} = MARKER_SKIP;
		}
		else {
			$markers{$def->name} = MARKER_LEAF;
		}

		my $path = $def->get_name_path;
		my @path_meta = @{$path->meta};
		for my $ind (0 .. $#path_meta) {
			if ($path_meta[$ind] eq 'ARRAY') {
				$markers{$path->join($ind - 1)} = MARKER_ARRAY;
			}
		}
	}

	my $error = try sub {
		$self->_check_recursive($obj, $input, \%markers);
	};

	if ($error) {
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

