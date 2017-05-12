package FBP::CustomControl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';

has class => (
	is  => 'ro',
	isa => 'Str',
);

has declaration => (
	is  => 'ro',
	isa => 'Str',
);

has construction => (
	is  => 'ro',
	isa => 'Str',
);

has include => (
	is  => 'ro',
	isa => 'Str',
);

has settings => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;




######################################################################
# Wx::Window Methods

sub wxclass {
	my $self = shift;

	# If a custom class is defined, use it literally
	my $subclass = $self->subclass;
	if ( length $subclass ) {
		my ($wxclass, $header) = split /\s*;\s*/, $subclass;
		if ( defined $wxclass and length $wxclass ) {
			return $wxclass;
		}
	}

	# Fall through to the explicit class property
	my $explicit = $self->class;
	if ( defined $explicit and length $explicit ) {
		return $explicit;
	}

	# No idea what to do at this point...
	die 'Failed to derive Wx class from FBP class';
}

sub header {
	my $self = shift;

	# If a custom class is defined, use it literally
	my $subclass = $self->subclass;
	if ( length $subclass ) {
		my ($wxclass, $header) = split /\s*;\s*/, $subclass;
		if ( defined $header and length $header ) {
			return $header;
		}
	}

	# Fall through to the explicit include string
	my $explicit = $self->include;
	if ( defined $explicit and length $explicit ) {
		return $explicit;
	}

	# If there is no explicit header to load, don't load anything
	return;
}

1;
