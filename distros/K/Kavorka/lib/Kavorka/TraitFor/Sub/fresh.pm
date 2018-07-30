use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Sub::fresh;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;
use Types::Standard qw(Any);
use Sub::Util ();
use Carp qw(croak);
use namespace::sweep;

my $stash_name = sub {
	Sub::Util::subname($_[0]) =~ m/^(.+)::(.+?)$/ ? $1 : undef;
};

before install_sub => sub
{
	my $self = shift;
	
	croak("The 'fresh' trait cannot be applied to lexical methods")
		if $self->is_lexical;
	
	croak("The 'fresh' trait cannot be applied to anonymous methods")
		if $self->is_anonymous;
	
	croak("The 'fresh' trait may only be applied to methods")
		if $self->invocation_style ne 'method';
	
	my ($pkg, $name) = ($self->qualified_name =~ /^(.+)::(\w+)$/);
	my $existing = $pkg->can($name) or return;
	my $existing_source = $stash_name->($existing);
	
	if ($pkg->isa($existing_source) or $existing_source eq 'UNIVERSAL')
	{
		croak("Method '$name' is inherited from '$existing_source'; not fresh");
	}
	
	if ($pkg->DOES($existing_source))
	{
		croak("Method '$name' is provided by role '$existing_source'; not fresh");
	}
	
	croak("Method '$name' already exists in inheritance hierarchy; possible namespace pollution; not fresh");
};

1;
