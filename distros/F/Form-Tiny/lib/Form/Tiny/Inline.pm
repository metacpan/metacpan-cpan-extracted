package Form::Tiny::Inline;
$Form::Tiny::Inline::VERSION = '2.16';
use v5.10;
use strict;
use warnings;

sub is
{
	my ($class, @roles) = @_;

	return Form::Tiny::Inline::Builder->create(@roles);
}

sub new
{
	my ($class, @params) = @_;

	return Form::Tiny::Inline::Builder->create()->new(@params);
}

# actual inline form package
{

	package Form::Tiny::Inline::Form;
$Form::Tiny::Inline::Form::VERSION = '2.16';
use v5.10;
	use strict;
	use warnings;

	use Types::Standard qw(InstanceOf);
	use Moo;

	# NOTE: consume this role eagerly
	# normally, it is part of the Base plugin, but it is also needed to have proper set
	# of constructor parameters. Since inline forms will have roles merged into the
	# objects themselves, this needs to be done beforehand
	with 'Form::Tiny::Form';

	has '_meta' => (
		is => 'ro',
		isa => InstanceOf ['Form::Tiny::Meta'],
		required => 1,
	);

	sub form_meta
	{
		my ($self) = @_;
		return $self->_meta;
	}

	sub BUILD
	{
		my ($self) = @_;

		require Moo::Role;
		Moo::Role->apply_roles_to_object(
			$self, @{$self->_meta->form_roles}
		) if @{$self->_meta->form_roles};
	}

}

# builder package to allow adding meta roles with no package magic
{

	package Form::Tiny::Inline::Builder;
$Form::Tiny::Inline::Builder::VERSION = '2.16';
use v5.10;
	use strict;
	use warnings;

	use Types::Standard qw(Str);

	use Form::Tiny::Utils qw(trim create_anon_form_meta);

	sub _build
	{
		my ($self, %args) = @_;

		# NOTE: called with caller = undef, context_ref = undef
		# not all plugins will be compatible with this, but that's okay
		require Form::Tiny;
		my $wanted = Form::Tiny->ft_run_plugins(undef, undef, @{$self->{plugins}});

		my $meta = create_anon_form_meta(@{$wanted->{meta_roles}});
		$meta->set_form_roles($wanted->{roles});
		$meta->bootstrap;

		if ($args{fields}) {
			for my $field_name (keys %{$args{fields}}) {
				$meta->add_field(
					{
						name => $field_name,
						%{$args{fields}{$field_name}},
					}
				);
			}
		}

		for my $field (@{$args{field_defs} // []}) {
			$meta->add_field($field);
		}

		if ($args{cleaner}) {
			$meta->add_hook(cleanup => $args{cleaner});
		}

		if ($meta->can('add_filter')) {
			$meta->add_global_trim_filter;

			for my $filter (@{$args{filters} // []}) {
				$meta->add_filter(@$filter);
			}
		}

		return Form::Tiny::Inline::Form->new(%args, _meta => $meta);
	}

	sub create
	{
		my ($self, @plugins) = @_;

		@plugins = map { ucfirst lc $_ } @plugins;

		return bless {
			plugins => \@plugins
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

		return $self->_build(%params);
	}
}

1;

__END__

=head1 NAME

Form::Tiny::Inline - Form::Tiny with less hassle

=head1 SYNOPSIS

	my $form = Form::Tiny::Inline->new(
		field_defs => [
			{name => 'some_field'},
			...
		],
	);

=head1 DESCRIPTION

Inline forms are designed to cover all the basic use cases, but they are not as customizable and performant. Currently, they lack the ability to specify custom hooks, field filters, field validators. Furthermore, non-core plugins may be incompatible with inline forms.

=head1 METHODS

=head2 is

When ran on a Form::Tiny::Inline class, it produces a new object that you can call C<< ->new >> on.

	my $inline_form_builder = Form::Tiny::Inline->is('Filtered', 'Strict');
	my $form = $inline_form_builder->new(%params);

Arguments passed to C<is> are names of plugins that will be used in the inline form. Not all plugins may be compatible with inline forms.

Note: callng C<is> is not required, if you don't intend to use additional plugins.

=head2 new

Constructs a new object of C<Form::Tiny::Inline::Form> class. This class consumes L<Form::Tiny::Form>, so refer to its interface for details.

	my $form = Form::Tiny::Inline->new(%params);

