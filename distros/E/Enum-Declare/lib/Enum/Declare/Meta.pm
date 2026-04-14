package Enum::Declare::Meta;

use strict;
use warnings;
use Carp qw/croak/;
use Object::Proto;

BEGIN {
	object 'Enum::Declare::Meta',
	'enum_name:Str:required',
	'package:Str:required',
	'names:ArrayRef:required',
	'values:ArrayRef:required',
	'name2val:HashRef:required',
	'val2name:HashRef:required';
}

sub name {
	my ($self, $val) = @_;
	return $self->val2name->{$val};
}

sub value {
	my ($self, $name) = @_;
	return $self->name2val->{$name};
}

sub valid {
	my ($self, $val) = @_;
	return exists $self->val2name->{$val} ? 1 : 0;
}

sub pairs {
	my ($self) = @_;
	my @names  = @{ $self->names };
	my @values = @{ $self->values };
	return map { $names[$_] => $values[$_] } 0 .. $#names;
}

sub count {
	my ($self) = @_;
	return scalar @{ $self->names };
}

sub match {
	my ($self, $val, $handlers) = @_;
	my @names = @{ $self->names };
	my $has_default = exists $handlers->{'_'};

	unless ($has_default) {
		my @missing = grep { !exists $handlers->{$_} } @names;
		if (@missing) {
			croak("Non exhaustive match for " . $self->enum_name
				. ": missing " . join(', ', @missing));
		}
	}

	my $variant = $self->val2name->{$val};
	if (defined $variant && exists $handlers->{$variant}) {
		return $handlers->{$variant}->($val);
	}
	if ($has_default) {
		return $handlers->{'_'}->($val);
	}
	croak("No match for value '$val' in " . $self->enum_name);
}

1;
