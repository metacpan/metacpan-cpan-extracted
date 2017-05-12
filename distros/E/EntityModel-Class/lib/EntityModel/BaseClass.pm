package EntityModel::BaseClass;
$EntityModel::BaseClass::VERSION = '0.016';
use strict;
use warnings;

use Scalar::Util ();
use EntityModel::Log ':all';

=head2 new

Basic constructor. Will populate $self with any parameters passed.

Returns the new instance.

=cut

sub new {
	my $class = shift;
	my %data;
	if(ref($_[0]) eq 'HASH') {
		%data = %{$_[0]};
	} else {
		if(@_ % 2) {
			logStack("Bad element list for [%s] - %s", $class, join(',', map { $_ // 'undef' } @_));
		}
		%data = @_;
	}
	my $self = bless \%data, $class;
	my @defaults = EntityModel::Class::has_defaults($class);
	return $self unless @defaults;

	foreach my $attr (grep { !exists $data{$_} } @defaults) {
		my $def = EntityModel::Class::_attrib_info($class, $attr);
		my $v = $def->{default};
		$v = $v->() if (ref($v) // '') eq 'CODE';
		# Still aliased to $self
		$data{$attr} = $v;
	}
	return $self;
}

=head2 clone

Shallow clone implementation.

Returns a new instance with a copy of everything in the hashref.

=cut

sub clone {
	my $self = shift;
	return bless { %$self }, ref $self;
}

=head2 dump

Simple method to dump out this object and all attributes.

=cut

sub dump {
	my $self = shift;
	my $out = shift || sub {
		my $k = shift;
		my $depth = shift;
		my $v = shift // '';
		print((' ' x $depth) . "$k = $v\n");
	};
	my $depth = shift // 0;

	$out->(ref($self), $depth, $self);
	foreach my $k (sort $self->ATTRIBS) {
		my $v = $self->$k();
		if(eval { $v->can('dump'); }) {
			$out->($k, $depth + 1, ':');
			$v->dump($out, $depth + 1);
		} elsif(ref $v eq 'ARRAY') {
			$out->($k, $depth + 1, '[' . join(',', @$v) . ']');
		} elsif(ref $v eq 'HASH') {
			$out->($k, $depth + 1, '{' . (map { $_ . ' => ' . $v->{$_} } sort keys %$v) . '}');
		} else {
			$out->($k, $depth + 1, $v);
		}
	}
	$self;
}

=head2 sap

Generate a coderef that takes a weakened value of $self.

Usage:

 push @handler, $obj->sap(sub {
 	my $self = shift;
	$self->do_something;
 });

=cut

sub sap {
	my ($self, $sub) = @_;
	Scalar::Util::weaken $self;
	return sub {
		$self->$sub(@_);
	};
}

1;
