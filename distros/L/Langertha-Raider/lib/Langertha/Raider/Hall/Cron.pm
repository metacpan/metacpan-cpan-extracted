package Langertha::Raider::Hall::Cron;
our $VERSION = '0.503';
# ABSTRACT: Internal non-blocking cron scheduler for the raider hall


# Non-blocking cron: for each entry we compute the next execution time via
# Schedule::Cron and arm an IO::Async::Timer::Absolute. When it fires we
# spawn the raider, then re-arm for the following occurrence. Overlap is
# controlled per-entry: by default an occurrence waits in the hall's queues
# behind the previous run; opt-in coalesce drops it while the previous run
# is still running or waiting.

use Moose;
use namespace::autoclean;
use Schedule::Cron;
use IO::Async::Timer::Absolute;

has hall => (
  is => 'ro',
  isa => 'Langertha::Raider::Hall',
  required => 1,
  weak_ref => 1,
);

has _jobs => (
  is => 'ro',
  default => sub { {} },
);

# A single parsing helper — we only use Schedule::Cron to compute the next
# time from the expression; we never call its own run loop.
sub _next_time_for {
  my ($self, $expr) = @_;
  my $sc = Schedule::Cron->new(sub { }, nofork => 1);
  my $idx = $sc->add_entry($expr, sub { });
  return $sc->get_next_execution_time($expr);
}

sub add_job {
  my ($self, %args) = @_;
  my $id = $args{id} // die "need id";
  my $cron_expr = $args{cron} // die "need cron expr";
  my $name = $args{name} // die "need name";
  my $mission = $args{mission} // '';
  my $coalesce = $args{coalesce} // 0;

  $self->_jobs->{$id} = {
    id => $id,
    cron => $cron_expr,
    name => $name,
    mission => $mission,
    coalesce => $coalesce,
  };
  $self->_arm($id);
  return $id;
}

sub _arm {
  my ($self, $id) = @_;
  my $job = $self->_jobs->{$id} or return;
  my $when = eval { $self->_next_time_for($job->{cron}) };
  return unless $when;

  my $timer = IO::Async::Timer::Absolute->new(
    time => $when,
    on_expire => sub { $self->_fire($id) },
  );
  $job->{timer} = $timer;
  $self->hall->loop->add($timer);
}

# One occurrence of a job: spawn its raider on the job's own session
# binding (cron:ID), then re-arm for the next one.
sub _fire {
  my ($self, $id) = @_;
  my $t = $self->_jobs->{$id};
  return unless $t;  # cancelled
  if ($t->{coalesce} && $self->_in_flight($id)) {
    $self->hall->_emit('cron.coalesced', { id => $id, name => $t->{name} });
  } else {
    my $res = eval { $self->hall->spawn(name => $t->{name}, mission => $t->{mission}, binding => 'cron:'.$id) };
    $t->{raider_id} = $res && $res->{id};
    $self->hall->_emit('cron.fired', {
      id => $id, name => $t->{name},
      ($res && $res->{id} ? (raider_id => $res->{id}) : ()),
    });
  }
  $self->_arm($id);  # re-schedule next occurrence
}

# Whether the job's previous occurrence has not ended yet, as the hall sees
# it: the raider it spawned is still running (also when the binding's
# session could not be had and it runs unbound), or a run on the job's
# binding is running or waiting in a queue.
sub _in_flight {
  my ($self, $id) = @_;
  my $hall = $self->hall;
  my $raider_id = $self->_jobs->{$id}{raider_id};
  return 1 if defined $raider_id && $hall->raiders->{$raider_id};
  my $binding = 'cron:'.$id;
  return 1 if $hall->_binding_busy($binding);
  return scalar grep { $_ eq $binding } $hall->_waiting_bindings;
}

sub start {
  my ($self) = @_;
  my $conf = $self->hall->config;
  my $cron_list = $conf->{cron} // [];
  for my $entry (@$cron_list) {
    $self->add_job(
      id => $entry->{id} // $entry->{name},
      cron => $entry->{cron},
      name => $entry->{name},
      mission => $entry->{mission} // '',
      coalesce => $entry->{coalesce} // 0,
    );
  }
}

sub cancel_job {
  my ($self, $id) = @_;
  my $job = delete $self->_jobs->{$id} or return;
  if ($job->{timer}) {
    eval { $self->hall->loop->remove($job->{timer}) };
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::Cron - Internal non-blocking cron scheduler for the raider hall

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Arms an L<IO::Async::Timer::Absolute> per configured cron entry of a
L<Langertha::Raider::Hall> and spawns the named raider when it fires.
Every job runs in a session of its own, bound as C<cron:ID>, which each
occurrence continues. An occurrence whose previous run has not ended yet
waits for it in the hall's queues; with C<coalesce: true> it is dropped
instead and the hall emits C<cron.coalesced>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
