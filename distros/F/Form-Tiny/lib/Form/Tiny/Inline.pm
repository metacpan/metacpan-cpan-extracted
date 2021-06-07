package Form::Tiny::Inline;

use v5.10;
use warnings;
use Types::Standard qw(Str ArrayRef InstanceOf);
use Moo;

use Form::Tiny::Form;
use Form::Tiny::Meta;
use Form::Tiny::Utils qw(trim create_anon_form_meta);

use namespace::clean;

our $VERSION = '2.01';

with 'Form::Tiny::Form';

has '_meta' => (
	is => 'ro',
	isa => InstanceOf ['Form::Tiny::Meta'],
	builder => '_build_meta',
	init_arg => undef,
	default => sub {
		my ($self) = @_;
		my $meta = create_anon_form_meta(@{$self->_meta_roles});
		$meta->setup;

		return $meta;
	},
	lazy => 1,
);

has '_meta_roles' => (
	is => 'ro',
	isa => ArrayRef,
	default => sub { [] },
);

sub BUILD
{
	my ($self, $args) = @_;

	my $meta = $self->form_meta;
	for my $field (@{$args->{field_defs} // []}) {
		$meta->add_field($field);
	}

	if ($args->{cleaner}) {
		$meta->add_hook(cleanup => $args->{cleaner});
	}

	if ($meta->can('add_filter')) {
		$meta->add_filter(Str, \&trim);
		for my $filter (@{$args->{filters} // []}) {
			$meta->add_filter(@$filter);
		}
	}
}

sub is
{
	my ($class, @roles) = @_;

	return Form::Tiny::Inline::Builder->create(@roles);
}

sub form_meta
{
	my ($self) = @_;
	return $self->_meta;
}

# builder package to allow adding meta roles with no package magic
{

	package Form::Tiny::Inline::Builder;

	use Types::Standard qw(RoleName Str);

	sub create
	{
		my ($self, @roles) = @_;

		@roles = map { ucfirst lc $_ } @roles;
		my $loader = q{ my $n = "Form::Tiny::Meta::$_"; eval "require $n"; $n; };
		my $type = RoleName->plus_coercions(Str, $loader);
		my @real_roles = map { $type->assert_coerce($_) } @roles;

		return bless {
			roles => \@real_roles
		}, $self;
	}

	sub new
	{
		my $self = shift;
		my %params;
		if (@_ == 1 && ref $_[0] eq 'HASH') {
			%params = %{$_[0]};
		}
		else {
			%params = @_;
		}

		$params{_meta_roles} = $self->{roles};

		return Form::Tiny::Inline->new(%params);
	}
}

1;

__END__

=head1 NAME

Form::Tiny::Inline - Form::Tiny without hassle

=head1 SYNOPSIS

	my $form = Form::Tiny::Inline->new(
		field_defs => [
			{name => "some_field"},
			...
		],
	);

=head1 DESCRIPTION

Inline forms are designed to cover all the basic use cases, but they are not as customizable. Currently, they lack the ability to specify custom hooks.

=head1 METHODS

=head2 is

When ran on a Form::Tiny::Inline class, it produces a new object that you can call C<< ->new >> on.

	$inline_form_builder = Form::Tiny::Inline->is("Filtered", "Strict");
