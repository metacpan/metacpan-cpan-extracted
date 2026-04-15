package Enum::Declare::Set;

use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/looks_like_number/;
use Object::Proto;

use overload
	'""'   => \&_stringify,
	'=='   => \&equals,
	'!='   => sub { !$_[0]->equals($_[1]) },
	'bool' => sub { !$_[0]->is_empty },
	fallback => 1;

object 'Enum::Declare::Set',
	'meta:required',
	'name:Str:default()',
	'frozen:Bool:default(0)',
	'bits:Str:default()',
	'init_values:ArrayRef:default([]):arg(values)';

sub BUILD {
	my ($self) = @_;
	my $count = $self->meta->count;
	my $bits  = '';
	vec($bits, $count - 1, 1) = 0 if $count;

	for my $val (@{$self->init_values}) {
		my $idx = _val_to_index($self, $val);
		vec($bits, $idx, 1) = 1;
	}

	$self->bits($bits);
}

sub has {
	my ($self, $val) = @_;
	my $idx = eval { $self->_val_to_index($val) };
	return 0 unless defined $idx;
	return vec($self->bits, $idx, 1) ? 1 : 0;
}

sub add {
	my ($self, @vals) = @_;
	$self->_assert_mutable;
	my $bits = $self->bits;
	for my $val (@vals) {
		my $idx = $self->_val_to_index($val);
		vec($bits, $idx, 1) = 1;
	}
	$self->bits($bits);
	return $self;
}

sub remove {
	my ($self, @vals) = @_;
	$self->_assert_mutable;
	my $bits = $self->bits;
	for my $val (@vals) {
		my $idx = $self->_val_to_index($val);
		vec($bits, $idx, 1) = 0;
	}
	$self->bits($bits);
	return $self;
}

sub toggle {
	my ($self, @vals) = @_;
	$self->_assert_mutable;
	my $bits = $self->bits;
	for my $val (@vals) {
		my $idx = $self->_val_to_index($val);
		vec($bits, $idx, 1) = vec($bits, $idx, 1) ? 0 : 1;
	}
	$self->bits($bits);
	return $self;
}

sub members {
	my ($self) = @_;
	my $names  = $self->meta->names;
	my $n2v    = $self->meta->name2val;
	my $bits   = $self->bits;
	my @out;
	for my $i (0 .. $#$names) {
		push @out, $n2v->{$names->[$i]} if vec($bits, $i, 1);
	}
	return @out;
}

sub names {
	my ($self) = @_;
	my $all_names = $self->meta->names;
	my $bits      = $self->bits;
	my @out;
	for my $i (0 .. $#$all_names) {
		push @out, $all_names->[$i] if vec($bits, $i, 1);
	}
	return @out;
}

sub count {
	my ($self) = @_;
	my $n = 0;
	my $total = $self->meta->count;
	my $bits  = $self->bits;
	for my $i (0 .. $total - 1) {
		$n++ if vec($bits, $i, 1);
	}
	return $n;
}

sub is_empty {
	my ($self) = @_;
	return $self->count == 0 ? 1 : 0;
}

sub clone {
	my ($self) = @_;
	my $new = Enum::Declare::Set->new(
		meta => $self->meta,
		name => $self->name,
	);
	$new->bits($self->bits);
	return $new;
}

# Set algebra — return new mutable Set

sub union {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	my $new = $self->clone;
	$new->bits($self->bits | $other->bits);
	return $new;
}

sub intersection {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	my $new = $self->clone;
	$new->bits($self->bits & $other->bits);
	return $new;
}

sub difference {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	my $new = $self->clone;
	$new->bits($self->bits & ~$other->bits);
	return $new;
}

sub symmetric_difference {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	my $new = $self->clone;
	$new->bits($self->bits ^ $other->bits);
	return $new;
}

# Comparisons

sub is_subset {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	return ($self->bits & $other->bits) eq $self->bits ? 1 : 0;
}

sub is_superset {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	return $other->is_subset($self);
}

sub is_disjoint {
	my ($self, $other) = @_;
	$self->_assert_same_enum($other);
	my $inter = $self->bits & $other->bits;
	return $inter eq ("\0" x length($inter)) ? 1 : 0;
}

sub equals {
	my ($self, $other) = @_;
	return 0 unless ref($other) && $other->isa(__PACKAGE__);
	$self->_assert_same_enum($other);
	return $self->bits eq $other->bits ? 1 : 0;
}

sub _val_to_index {
	my ($self, $val) = @_;
	my $v2n = $self->meta->val2name;
	croak("Invalid enum value '$val' for " . $self->meta->enum_name)
		unless exists $v2n->{$val};
	my $names = $self->meta->names;
	for my $i (0 .. $#$names) {
		return $i if $self->meta->name2val->{$names->[$i]} eq $val
			|| (looks_like_number($val)
				&& looks_like_number($self->meta->name2val->{$names->[$i]})
				&& $self->meta->name2val->{$names->[$i]} == $val);
	}
	croak("Value '$val' not found in " . $self->meta->enum_name);
}

sub _assert_mutable {
	my ($self) = @_;
	croak("cannot modify a frozen set") if $self->frozen;
}

sub _assert_same_enum {
	my ($self, $other) = @_;
	croak("sets belong to different enums")
		unless $self->meta->enum_name eq $other->meta->enum_name
		    && $self->meta->package   eq $other->meta->package;
}

# Stringification

sub _stringify {
	my ($self) = @_;
	my $label = $self->name || 'Set';
	return $label . '(' . join(', ', $self->names) . ')';
}

1;
