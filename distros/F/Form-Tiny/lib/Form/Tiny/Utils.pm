package Form::Tiny::Utils;

use v5.10;
use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);

our $VERSION = '2.04';
our @EXPORT;
our @EXPORT_OK = qw(
	try
	trim
	uniq
	create_anon_form_meta
	create_form_meta
	get_package_form_meta
	set_form_meta_class
);

our %EXPORT_TAGS = (
	meta_handlers => [
		qw(
			create_anon_form_meta
			create_form_meta
			get_package_form_meta
			set_form_meta_class
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

sub get_package_form_meta
{
	my ($package_name) = @_;

	croak "no form meta declared for $package_name"
		unless exists $meta{$package_name};

	my $form_meta = $meta{$package_name};

	if (!$form_meta->complete) {

		# when this breaks, mst gets to point and laugh at me
		my @parents = do {
			no strict 'refs';
			@{"${package_name}::ISA"};
		};

		my @real_parents = grep { $_->DOES('Form::Tiny::Form') } @parents;

		croak 'Form::Tiny does not support multiple inheritance'
			if @real_parents > 1;

		my ($parent) = @real_parents;
		$form_meta->inherit_roles_from($parent ? $parent->form_meta : undef);
		$form_meta->inherit_from($parent->form_meta) if $parent;
		$form_meta->setup;
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

1;
