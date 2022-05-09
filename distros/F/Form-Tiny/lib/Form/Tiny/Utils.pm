package Form::Tiny::Utils;

use v5.10;
use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);

our $VERSION = '2.12';
our @EXPORT;
our @EXPORT_OK = qw(
	try
	trim
	uniq
	create_anon_form_meta
	create_form_meta
	get_package_form_meta
	set_form_meta_class
	has_form_meta
);

our %EXPORT_TAGS = (
	meta_handlers => [
		qw(
			create_anon_form_meta
			create_form_meta
			get_package_form_meta
			set_form_meta_class
			has_form_meta
		)
	],
);

sub try
{
	my ($sub) = @_;

	local $@;
	my $ret = not eval {
		$sub->();
		return 1;
	};

	if ($@ && $ret) {
		$ret = $@;
	}

	return $ret;
}

sub trim
{
	my ($value) = @_;
	$value =~ s/\A\s+//;
	$value =~ s/\s+\z//;

	return $value;
}

sub uniq
{
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

# FORM METADATA
my $meta_class = 'Form::Tiny::Meta';
my %meta;

sub create_anon_form_meta
{
	my (@roles) = @_;
	require Form::Tiny::Meta;
	my $meta = $meta_class->new;
	$meta->set_meta_roles([@roles]);

	return $meta;
}

sub create_form_meta
{
	my ($package, @roles) = @_;

	croak "form meta for $package already exists"
		if exists $meta{$package};

	$meta{$package} = create_anon_form_meta(@roles);
	$meta{$package}->set_package($package);

	return $meta{$package};
}

sub has_form_meta
{
	return exists $meta{ref $_[0] || $_[0]};
}

sub get_package_form_meta
{
	# short-circuit if the meta has already been built
	return $meta{$_[0]} if $meta{$_[0]} && $meta{$_[0]}->complete;

	my ($package_name) = @_;

	croak "no form meta declared for $package_name"
		unless exists $meta{$package_name};

	my $form_meta = $meta{$package_name};

	$form_meta->bootstrap;

	return $form_meta;
}

sub set_form_meta_class
{
	my ($class) = @_;

	croak 'form meta class must extend Form::Tiny::Meta'
		unless $class->DOES('Form::Tiny::Meta');

	$meta_class = $class;
	return;
}

# internal use functions (not exported)

sub _find_field
{
	my ($fields, $field_def) = @_;

	my @path = @{$field_def->get_name_path->path};
	my @arrays = map { $_ eq 'ARRAY' } @{$field_def->get_name_path->meta};

	# the result goes here
	my @found;
	my $traverser;
	$traverser = sub {
		my ($curr_path, $index, $value) = @_;

		if ($index == @path) {

			# we reached the end of the tree
			push @found, [$curr_path, $value];
		}
		else {
			my $is_array = $arrays[$index];
			my $current_ref = ref $value;

			# make sure the actual ref type does not mismatch the spec
			return unless $is_array eq ($current_ref eq 'ARRAY');

			# it's not the leaf of the tree yet, so we require an array or a hash
			return if !$is_array && $current_ref ne 'HASH';

			if ($is_array) {
				if (@$value == 0) {

					# we wanted to have a deeper structure, but its not there, so clearly an error
					return unless $index == $#path;

					# we had aref here, so we want it back in resulting hash
					push @found, [$curr_path, [], 1];
				}
				else {
					for my $ind (0 .. $#$value) {
						return    # may be an error, exit early
							unless $traverser->([@$curr_path, $ind], $index + 1, $value->[$ind]);
					}
				}
			}

			else {
				my $next = $path[$index];
				return unless exists $value->{$next};
				return $traverser->([@$curr_path, $next], $index + 1, $value->{$next});
			}
		}

		return 1;    # all ok
	};

	if ($traverser->([], 0, $fields)) {
		return [
			map {
				{
					path => $_->[0],
					value => $_->[1],
					structure => $_->[2]
				}
			} @found
		];
	}
	return;
}

sub _assign_field
{
	my ($fields, $field_def, $path_values) = @_;

	my @arrays = map { $_ eq 'ARRAY' } @{$field_def->get_name_path->meta};
	for my $path_value (@$path_values) {
		my @parts = @{$path_value->{path}};
		my $current = \$fields;
		for my $i (0 .. $#parts) {

			# array_path will contain array indexes for each array marker
			if ($arrays[$i]) {
				$current = \${$current}->[$parts[$i]];
			}
			else {
				$current = \${$current}->{$parts[$i]};
			}
		}

		$$current = $path_value->{value};
	}
}

1;

