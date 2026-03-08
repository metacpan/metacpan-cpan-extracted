package Linux::Event::Scheduler;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use v5.36;
use strict;
use warnings;

use Carp qw(croak);

sub new ($class, %args) {
  my $clock = delete $args{clock};
  croak "clock is required" if !$clock;
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  for my $m (qw(now_ns deadline_in_ns)) {
    croak "clock missing method '$m'" if !$clock->can($m);
  }

  return bless {
    clock     => $clock,
    d_ns      => [],
    cb        => [],
    id        => [],
    size      => 0,
    next_id   => 1,
    live      => {},
    cancelled => 0,
  }, $class;
}

sub at_ns ($self, $deadline_ns, $cb) {
  croak "deadline_ns is required" if !defined $deadline_ns;
  croak "callback is required"    if !defined $cb;
  croak "callback must be a coderef" if ref($cb) ne 'CODE';

  $deadline_ns = int($deadline_ns);

  my $id = $self->{next_id}++;
  $self->{live}{$id} = 1;

  my $i = $self->{size}++;
  $self->{d_ns}[$i] = $deadline_ns;
  $self->{cb}[$i]   = $cb;
  $self->{id}[$i]   = $id;

  _sift_up($self, $i);
  return $id;
}

sub after_ns ($self, $delta_ns, $cb) {
  croak "delta_ns is required" if !defined $delta_ns;
  $delta_ns = int($delta_ns);
  my $deadline = $self->{clock}->deadline_in_ns($delta_ns);
  return $self->at_ns($deadline, $cb);
}

sub cancel ($self, $id) {
  return 0 if !defined $id;
  return 0 if !$self->{live}{$id};
  delete $self->{live}{$id};
  $self->{cancelled}++;
  return 1;
}

sub next_deadline_ns ($self) {
  _compact($self) if $self->{cancelled} && $self->{cancelled} > 32;
  return undef if !$self->{size};
  my $id0 = $self->{id}[0];
  while ($self->{size} && !$self->{live}{$id0}) {
    _pop_root($self);
    return undef if !$self->{size};
    $id0 = $self->{id}[0];
  }
  return $self->{d_ns}[0];
}

sub pop_expired ($self) {
  my $now = $self->{clock}->now_ns;

  my @out;
  while ($self->{size}) {
    my $deadline = $self->{d_ns}[0];
    my $id0      = $self->{id}[0];

    if (!$self->{live}{$id0}) {
      _pop_root($self);
      next;
    }

    last if $deadline > $now;

    my $cb = $self->{cb}[0];

    delete $self->{live}{$id0};
    _pop_root($self);

    push @out, [ $id0, $cb, $deadline ];
  }
  return @out;
}

sub _pop_root ($self) {
  my $last = --$self->{size};
  if ($last < 0) {
    $self->{size} = 0;
    return;
  }
  if ($last == 0) {
    $self->{d_ns} = [];
    $self->{cb}   = [];
    $self->{id}   = [];
    return;
  }

  $self->{d_ns}[0] = $self->{d_ns}[$last];
  $self->{cb}[0]   = $self->{cb}[$last];
  $self->{id}[0]   = $self->{id}[$last];

  pop @{ $self->{d_ns} };
  pop @{ $self->{cb} };
  pop @{ $self->{id} };

  _sift_down($self, 0);
  return;
}

sub _sift_up ($self, $i) {
  while ($i > 0) {
    my $p = int(($i - 1) / 2);
    last if $self->{d_ns}[$p] <= $self->{d_ns}[$i];
    _swap($self, $i, $p);
    $i = $p;
  }
  return;
}

sub _sift_down ($self, $i) {
  while (1) {
    my $l = $i * 2 + 1;
    last if $l >= $self->{size};
    my $r = $l + 1;

    my $m = $l;
    if ($r < $self->{size} && $self->{d_ns}[$r] < $self->{d_ns}[$l]) {
      $m = $r;
    }

    last if $self->{d_ns}[$i] <= $self->{d_ns}[$m];
    _swap($self, $i, $m);
    $i = $m;
  }
  return;
}

sub _swap ($self, $a, $b) {
  (@{$self->{d_ns}}[$a, $b]) = (@{$self->{d_ns}}[$b, $a]);
  (@{$self->{cb}}[$a, $b])   = (@{$self->{cb}}[$b, $a]);
  (@{$self->{id}}[$a, $b])   = (@{$self->{id}}[$b, $a]);
  return;
}

sub _compact ($self) {
  # Rebuild heap to drop cancelled entries.
  return if !$self->{size};

  my @d;
  my @cb;
  my @id;

  for my $i (0 .. $self->{size} - 1) {
    my $idv = $self->{id}[$i];
    next if !$self->{live}{$idv};
    push @d,  $self->{d_ns}[$i];
    push @cb, $self->{cb}[$i];
    push @id, $idv;
  }

  $self->{d_ns} = \@d;
  $self->{cb}   = \@cb;
  $self->{id}   = \@id;
  $self->{size} = scalar @id;
  $self->{cancelled} = 0;

  # Heapify
  for (my $i = int($self->{size} / 2) - 1; $i >= 0; $i--) {
    _sift_down($self, $i);
  }
  return;
}

1;

1;

__END__

=head1 NAME

Linux::Event::Scheduler - Internal timer queue for Linux::Event

=head1 SYNOPSIS

  # Internal module. See Linux::Event::Loop.

=head1 DESCRIPTION

This package implements the timer queue used by L<Linux::Event::Loop>.
It stores timers keyed by monotonic time and supports popping all
expired timers for a given time point.

This module is not intended for direct use.

=head1 METHODS

This class is internal; method names and behavior may change without notice.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=head1 VERSION

This document describes Linux::Event::Scheduler version 0.006.

=cut
