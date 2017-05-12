package EntityModel::Array;
$EntityModel::Array::VERSION = '0.016';
use strict;
use warnings;

use parent qw(Mixin::Event::Dispatch);

use EntityModel::Log ':all';

=head1 NAME

EntityModel::Array - wrapper object for dealing with arrayrefs

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

Primarily intended as an abstract interface for use with L<EntityModel> backend storage.

=head1 METHODS

=cut

use overload
	'@{}' => sub {
		my $self = shift;
		return $self->{data};
	},
	fallback => 1;

=head2 new

Instantiates with the given arrayref

=cut

sub new {
	my ($class, $data, %opt) = @_;
	bless {
		%opt,
		data => ($data || [ ]),
	}, $class;
}

=head2 count

Returns the number of items in the arrayref if called
without parameters. This is the recommended usage.

If passed a coderef, will call that coderef with the count,
and return $self instead.

=cut

sub count {
	my $self = shift;
	my $count = scalar @{$self->{data}};
	if(@_) {
		$_->($count) for @_;
		return $self;
	}
	return $count;
}

=head2 list

Returns all items from the arrayref.

=cut

sub list {
	my $self = shift;
	return unless $self->{data};
	return @{$self->{data}};
}

=head2 push

Push the requested value onto the end of the arrayref.

=cut

sub push : method {
	my $self = shift;
	push @{$self->{data}}, @_;
	$self->invoke_event(push => @_);
	if($self->{onchange}) {
		foreach my $w (@{$self->{onchange}}) {
			$w->(add => $_) foreach @_;
		}
	}
	return $self;
}

=head2 splice

Support for the L<perlfunc/splice> operation.

Takes an offset, length and zero or more items, splices those into the array,
invokes the C< splice > event, then returns $self.

=cut

sub splice : method {
	my $self = shift;
	my $offset = shift;
	my $length = shift;
	splice @{$self->{data}}, $offset, $length, @_;
	$self->invoke_event(splice => $offset, $length, @_);
	$self
}

=head2 add_watch

Add a coderef to be called when the array changes.

=cut

sub add_watch : method {
	my $self = shift;
	$self->{onchange} ||= [];
	push @{$self->{onchange}}, @_;
	return $self;
}

=head2 remove_watch : method

Removes a watch from this array.

Returns $self.

=cut

sub remove_watch : method {
	my $self = shift;
	return $self unless $self->{onchange};
	foreach my $code (@_) {
		@{ $self->{onchange} } = grep { $_ != $code } @{ $self->{onchange} };
	}
	return $self;
}

=head2 shift

Shift the first value out of the arrayref.

=cut

sub shift : method {
	my $self = shift;
	my $v = shift(@{$self->{data}});
	$self->invoke_event(shift => $v);
	if($self->{onchange}) {
		foreach my $w (@{$self->{onchange}}) {
			$w->(drop => $v);
		}
	}
	return $v;
}

=head2 pop

Pops the last value from the arrayref.

=cut

sub pop : method {
	my $self = shift;
	my $v = pop(@{$self->{data}});
	$self->invoke_event(pop => $v);
	if($self->{onchange}) {
		foreach my $w (@{$self->{onchange}}) {
			$w->(drop => $v);
		}
	}
	return $v;
}

=head2 unshift

Unshifts a value onto the start of the arrayref.

=cut

sub unshift : method {
	my $self = shift;
	my $v = unshift @{$self->{data}}, @_;
	$self->invoke_event(unshift => @_);
	if($self->{onchange}) {
		foreach my $w (@{$self->{onchange}}) {
			$w->(add => $_) foreach @_;
		}
	}
	return $self;
}

=head2 join

Joins the entries in the arrayref using the given value and returns as a scalar.

=cut

sub join : method {
	my $self = shift;
	my $sep = shift;
	my $joined = join($sep, @{$self->{data}});
	if(@_) {
		$_->($joined) for @_;
		return $self;
	}
	return $joined;
}

=head2 each

Perform coderef on each entry in the arrayref.

=cut

sub each : method {
	my ($self, $code) = @_;
	$code->($_) for @{$self->{data}};
	return $self;
}

=head2 first

Returns the first entry in the arrayref.

=cut

sub first {
	my $self = shift;
	if(@_) {
		$_->($self->{data}[0]) for @_;
		return $self;
	}
	return $self->{data}[0];
}

=head2 last

Returns the last entry in the arrayref.

=cut

sub last {
	my $self = shift;
	if(@_) {
		$_->($self->{data}[-1]) for @_;
		return $self;
	}
	return $self->{data}[-1];
}

=head2 grep

Calls the coderef on each entry in the arrayref and returns the entries for which it returns true.

=cut

sub grep : method {
	my ($self, $match) = @_;
	return ref($self)->new([ grep { $match->($_) } @{$self->{data}} ]);
}

=head2 remove

Remove entries from the array.

Avoid rebuilding the array in case we have weak refs, just splice out the values
indicated.

=cut

sub remove : method {
	my ($self, $check) = @_;
	my $idx = 0;
	while($idx < scalar @{$self->{data}}) {
		my $match;
		if(ref $check eq 'CODE') {
			$match = $check->($self->{data}->[$idx]);
		} else {
			$match = $self->{data}[$idx] eq $check;
		}
		if($match) {
			my ($el) = splice @{$self->{data}}, $idx, 1;
			if($self->{onchange}) {
				foreach my $w (@{$self->{onchange}}) {
					$w->(drop => $el);
				}
			}
		} else {
			++$idx;
		}
	}
	return $self;
}

=head2 clear

Empty the arrayref.

=cut

sub clear : method {
	my $self = shift;
	if($self->{onchange}) {
		my @el = @{ $self->{data} };
		foreach my $w (@{$self->{onchange}}) {
			$w->(drop => $_) for @el;
		}
	}
	$self->{data} = [ ];
	return $self;
}

=head2 arrayref

Returns the arrayref directly.

=cut

sub arrayref {
	my ($self) = @_;
	return $self->{data};
}

=head2 is_empty

Returns true if there's nothing in the arrayref.

=cut

sub is_empty {
	my $self = shift;
	return !$self->count;
}

1;

__END__

=head1 SEE ALSO

Use L<autobox> instead.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
