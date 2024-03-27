package Form::Tiny::Utils;
$Form::Tiny::Utils::VERSION = '2.24';
use v5.10;
use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);
use Scalar::Util qw(blessed);

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
	return exists $meta{ref $_[0] || $_[0]}
		|| blessed $_[0] && $_[0]->DOES('Form::Tiny::Form');
}

sub get_package_form_meta
{
	my $package_name = ref $_[0] || $_[0];
	my $form_meta = $meta{$package_name};

	if (!$form_meta || !$form_meta->complete) {
		croak "no form meta declared for $package_name"
			unless exists $meta{$package_name};

		croak "Form $package_name seems to be empty. "
			. 'Please implement the form or call __PACKAGE__->form_meta explicitly. '
			. 'See Form::Tiny::Manual::Cookbook "Empty forms" section for details'
			if ref $_[0];

		$form_meta->bootstrap;
	}

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

# returns arrayref of subarraysrefs, each in format:
# [path_aref, $value, $is_structure]
sub _find_field
{
	my ($fields, $field_def) = @_;

	my @path = @{$field_def->get_name_path->path};
	my $arrays = $field_def->get_name_path->meta_arrays;

	# the result goes here
	my @found;
	my $traverser;
	$traverser = sub {
		my ($curr_path, $index, $value) = @_;

		while ($index < @path) {
			my $current_ref = ref $value;

			if ($arrays->[$index]) {

				# It's an array, make sure the actual ref type does not mismatch the spec
				return 0 unless $current_ref eq 'ARRAY';

				if (@$value == 0) {

					# we wanted to have a deeper structure, but its not there, so clearly an error
					return 0 unless $index == $#path;

					# we had aref here, so we want it back in resulting hash
					push @found, [$curr_path, [], 1];
				}
				else {
					for my $ind (0 .. $#$value) {
						return 0    # may be an error, exit early
							unless $traverser->([@$curr_path, $ind], $index + 1, $value->[$ind]);
					}
				}

				return 1;    # exit early, looping continued in recursive calls
			}

			else {
				# it's not the leaf of the tree yet, so we require a hash
				my $next = $path[$index];
				return 0 unless $current_ref eq 'HASH' && exists $value->{$next};

				$index += 1;
				$value = $value->{$next};
				push @$curr_path, $next;
			}
		}

		push @found, [$curr_path, $value];
		return 1;    # all ok
	};

	# manually free traverser after it's done (memory leak)
	my $result = $traverser->([], 0, $fields);
	$traverser = undef;

	return \@found if $result;
	return;
}

# takes the same format as _find_field returns (in $path_values), and fills it
# into $fields according to $field_def
sub _assign_field
{
	my ($fields, $field_def, $path_values) = @_;

	my $arrays = $field_def->get_name_path->meta_arrays;
	for my $path_value (@$path_values) {
		my @parts = @{$path_value->[0]};
		my $current = \$fields;

		for my $i (0 .. $#parts) {
			if ($arrays->[$i]) {
				$current = \${$current}->[$parts[$i]];
			}
			else {
				$current = \${$current}->{$parts[$i]};
			}
		}

		$$current = $path_value->[1];
	}
}

1;

