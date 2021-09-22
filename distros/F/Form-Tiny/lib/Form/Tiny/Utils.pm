package Form::Tiny::Utils;

use v5.10;
use warnings;
use Exporter qw(import);
use Carp qw(croak);

our $VERSION = '2.02';
our @EXPORT;
our @EXPORT_OK = qw(
	try
	trim
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

# FORM METADATA
my $meta_class = 'Form::Tiny::Meta';
my %meta;

sub create_anon_form_meta
{
	my (@roles) = @_;
	require Form::Tiny::Meta;
	my $meta = $meta_class->new;

	require Moo::Role;
	Moo::Role->apply_roles_to_object(
		$meta, @roles
	) if scalar @roles;

	return $meta;
}

sub create_form_meta
{
	my ($package, @roles) = @_;

	croak "form meta for $package already exists"
		if exists $meta{$package};

	$meta{$package} = create_anon_form_meta(@roles);

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

		foreach my $parent (@parents) {
			$form_meta->inherit_from($parent->form_meta)
				if $parent->DOES('Form::Tiny::Form');
		}
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
