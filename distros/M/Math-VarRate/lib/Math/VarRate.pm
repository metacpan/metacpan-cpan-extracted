use strict;
use warnings;
package Math::VarRate 0.100001;
# ABSTRACT: deal with linear, variable rates of increase

use Carp ();
use Scalar::Util ();

#pod =head1 DESCRIPTION
#pod
#pod Math::VarRate is a very, very poor man's calculus.  A Math::VarRate object
#pod represents an accumulator that increases at a varying rate over time.  The rate
#pod may change, it is always a linear, positive rate of change.
#pod
#pod You can imagine the rate as representing "units gained per time."  You can then
#pod interrogate the Math::VarRate object for the total units accumulated at any
#pod given offset in time, or for the time at which a given number of units will
#pod have first been accumulated.
#pod
#pod =method new
#pod
#pod   my $varrate = Math::VarRate->new(\%arg);
#pod
#pod Valid arguments to C<new> are:
#pod
#pod   rate_changes   - a hashref in which keys are offsets and values are rates
#pod   starting_value - the value at offset 0 (defaults to 0)
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  my $changes = $arg->{rate_changes} || {};
  my $self = bless {
    rate_changes   => $changes,
    starting_value => $arg->{starting_value} || 0,
  } => $class;

  $self->_sanity_check_rate_changes;
  $self->_precompute_offsets;

  return $self;
}

sub _sanity_check_rate_changes {
  my ($self) = @_;
  my $rc = $self->{rate_changes};

  my %check = (
    rates   => [ values %$rc ],
    offsets => [ keys %$rc   ],
  );

  while (my ($k, $v) = each %check) {
    Carp::confess("non-numeric $k are not allowed")
      if grep { ! Scalar::Util::looks_like_number("$_") } @$v;
    Carp::confess("negative $k are not allowed") if grep { $_ < 0 } @$v;
  }
}

#pod =method starting_value
#pod
#pod This method returns the value of the accumulator at offset 0.
#pod
#pod =cut

sub starting_value { $_[0]->{starting_value} || 0 }

#pod =method offset_for
#pod
#pod   my $offset = $varrate->offset_for($value);
#pod
#pod This method returns the offset (positive, from 0) at which the given value is
#pod reached.  If the given value will never be reached, undef will be returned.
#pod
#pod =cut

sub offset_for {
  my ($self, $value) = @_;

  Carp::croak("illegal value: non-numeric")
    unless Scalar::Util::looks_like_number("$value");

  Carp::croak("illegal value: negative") unless $value >= 0;

  $value += 0;

  return 0 if $value == $self->starting_value;

  my $ko       = $self->{known_offsets};
  my ($offset) = sort { $b <=> $a } grep { $ko->{ $_ } < $value } keys %$ko;

  return unless defined $offset;

  my $rate     = $self->{rate_changes}{ $offset };

  # If we stopped for good, we can never reach the target. -- rjbs, 2009-05-11
  return undef if $rate == 0;

  my $to_go    = $value - $ko->{ $offset };
  my $dur      = $to_go / $rate;

  return $offset + $dur;
}

#pod =method value_at
#pod
#pod   my $value = $varrate->value_at($offset);
#pod
#pod This returns the value in the accumulator at the given offset.
#pod
#pod =cut

sub value_at {
  my ($self, $offset) = @_;

  Carp::croak("illegal offset: non-numeric")
    unless Scalar::Util::looks_like_number("$offset");

  Carp::croak("illegal offset: negative") unless $offset >= 0;

  $offset += 0;

  my $known_offsets = $self->{known_offsets};

  return $known_offsets->{ $offset } if exists $known_offsets->{ $offset };

  my ($max) = sort { $b <=> $a } grep { $_ < $offset } keys %$known_offsets;

  return $self->starting_value unless defined $max;

  my $start = $known_offsets->{ $max };
  my $rate  = $self->{rate_changes}{ $max };
  my $dur   = $offset - $max;

  return $start  +  $rate * $dur;
}

sub _precompute_offsets {
  my ($self) = @_;

  my $value   = $self->starting_value;
  my $v_at_o  = {};
  my %changes = %{ $self->{rate_changes} };
  my $prev    = 0;
  my $rate    = 0;

  for my $offset (sort { $a <=> $b } keys %changes) {
    my $duration = $offset - $prev;

    $value += $duration * $rate;
    $v_at_o->{ $offset } = $value;

    $rate = $changes{ $offset };
    $prev = $offset;
  }

  $self->{known_offsets} = $v_at_o;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::VarRate - deal with linear, variable rates of increase

=head1 VERSION

version 0.100001

=head1 DESCRIPTION

Math::VarRate is a very, very poor man's calculus.  A Math::VarRate object
represents an accumulator that increases at a varying rate over time.  The rate
may change, it is always a linear, positive rate of change.

You can imagine the rate as representing "units gained per time."  You can then
interrogate the Math::VarRate object for the total units accumulated at any
given offset in time, or for the time at which a given number of units will
have first been accumulated.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $varrate = Math::VarRate->new(\%arg);

Valid arguments to C<new> are:

  rate_changes   - a hashref in which keys are offsets and values are rates
  starting_value - the value at offset 0 (defaults to 0)

=head2 starting_value

This method returns the value of the accumulator at offset 0.

=head2 offset_for

  my $offset = $varrate->offset_for($value);

This method returns the offset (positive, from 0) at which the given value is
reached.  If the given value will never be reached, undef will be returned.

=head2 value_at

  my $value = $varrate->value_at($offset);

This returns the value in the accumulator at the given offset.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
