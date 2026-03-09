package Linux::Event::Signal;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

use Carp qw(croak);
use Scalar::Util qw(weaken);
use POSIX ();

# External dependency for signalfd integration.
#
# This is loaded lazily so that the core loop can be used even when
# Linux::FD::Signal is not installed.

sub new ($class, %args) {
  my $loop = delete $args{loop};
  croak "loop is required" if !$loop;
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  weaken($loop);

  return bless {
    loop => $loop,

    _fh      => undef,  # Linux::FD::Signal filehandle
    _watcher => undef,  # Linux::Event::Watcher for the signalfd

    _mask    => POSIX::SigSet->new(),
    _blocked => POSIX::SigSet->new(),

    # signum -> { cb => CODE, data => any, sub => $sub }
    _handlers => {},
  }, $class;
}

sub loop ($self) { return $self->{loop} }

sub signal ($self, $sig_or_list, $cb, %opt) {
  croak "signal is required" if !defined $sig_or_list;
  croak "cb is required" if !$cb;
  croak "cb must be a coderef" if ref($cb) ne 'CODE';

  my $data = delete $opt{data};
  croak "unknown args: " . join(", ", sort keys %opt) if %opt;

  my @sigs;
  if (ref($sig_or_list) eq 'ARRAY') {
    @sigs = @$sig_or_list;
  }
  elsif (!ref($sig_or_list)) {
    @sigs = ($sig_or_list);
  }
  else {
    croak "signal must be a number, string, or arrayref";
  }

  @sigs = map { _sig_to_num($_) } @sigs;
  croak "no signals provided" if !@sigs;

  $self->_ensure_fd;

  my $sub = Linux::Event::Signal::Subscription->_new($self, \@sigs);

  # Replacement semantics: one handler per signal, last registration wins.
  for my $sig (@sigs) {
    $self->{_handlers}{$sig} = {
      cb   => $cb,
      data => $data,
      sub  => $sub,
    };

    # Our semantics freeze: the mask and blocked-set only grow for the lifetime
    # of the loop. We do not attempt to restore legacy signal state.
    if (!$self->{_mask}->ismember($sig)) {
      $self->{_mask}->addset($sig);
      $self->_block_signal($sig);
      $self->{_fh}->set_mask($self->{_mask});
    }
  }

  return $sub;
}

sub _sig_to_num ($sig) {
  croak "signal is undef" if !defined $sig;

  if (!ref($sig) && $sig =~ /\A\d+\z/) {
    return int($sig);
  }

  croak "signal must be a string or integer" if ref($sig);

  my $name = uc($sig);
  $name =~ s/\A\s+|\s+\z//g;
  $name =~ s/\A(SIG)//;

  my $const = "SIG$name";
  my $sub = POSIX->can($const);
  croak "unknown signal '$sig'" if !$sub;
  return int($sub->());
}

sub _ensure_fd ($self) {
  return if $self->{_fh};

  eval { require Linux::FD::Signal; 1 }
    or croak "Linux::FD::Signal is required for signal() support: $@";

  # Non-blocking is critical: epoll read readiness may be spuriously invoked
  # when multiple records are pending; we drain to EAGAIN.
  my $fh = Linux::FD::Signal->new($self->{_mask}, 'non-blocking');
  $self->{_fh} = $fh;

  my $loop = $self->{loop} or croak "loop has been destroyed";
  $self->{_watcher} = $loop->watch(
    $fh,
    read => sub ($loop, $fh2, $w) {
      $self->_drain_and_dispatch;
    },
  );

  return;
}

sub _block_signal ($self, $sig) {
  return if $self->{_blocked}->ismember($sig);
  $self->{_blocked}->addset($sig);
  POSIX::sigprocmask(POSIX::SIG_BLOCK(), $self->{_blocked});
  return;
}

sub _drain_and_dispatch ($self) {
  my $loop = $self->{loop};
  return if !$loop;

  my $fh = $self->{_fh} or return;

  my %count;

  while (1) {
    my $info = eval { $fh->receive };
    if (!$info) {
      # Linux::FD::Signal returns undef on EAGAIN (non-blocking), and sets $!.
      last if $!{EAGAIN} || $!{EWOULDBLOCK};
      last if $@ && ($@ =~ /EAGAIN/);
      die $@ if $@;
      last;
    }

    my $sig = $info->{signo};
    $count{$sig}++ if defined $sig;
  }

  return if !%count;

  # Dispatch: per-signal callback, once per dispatch cycle.
  for my $sig (sort { $a <=> $b } keys %count) {
    my $h = $self->{_handlers}{$sig} or next;
    my $cb = $h->{cb} or next;
    $cb->($loop, $sig, $count{$sig}, $h->{data});
  }

  return;
}

sub _cancel_subscription ($self, $sub) {
  # Remove mappings only if they still point at this subscription.
  for my $sig (@{ $sub->{_sigs} }) {
    my $h = $self->{_handlers}{$sig} or next;
    next if !$h->{sub} || $h->{sub} != $sub;
    delete $self->{_handlers}{$sig};
  }
  return;
}


package Linux::Event::Signal::Subscription;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(weaken);

sub _new ($class, $signal, $sigs) {
  weaken($signal);
  return bless {
    _signal => $signal,
    _sigs   => [@$sigs],
    _active => 1,
  }, $class;
}

sub cancel ($self) {
  return 0 if !$self->{_active};
  $self->{_active} = 0;
  my $signal = $self->{_signal};
  $signal->_cancel_subscription($self) if $signal;
  return 1;
}

sub is_active ($self) { return $self->{_active} ? 1 : 0 }

1;

__END__

=head1 NAME

Linux::Event::Signal - signalfd adaptor for Linux::Event::Reactor

=head1 SYNOPSIS

<<<<<<< HEAD
=======
  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new( model => 'reactor' );

  # Subscribe via the loop convenience method:
>>>>>>> 1401c31 (prep for cpan and release, new tool added)
  my $sub = $loop->signal('INT', sub ($loop, $sig, $count, $data) {
    $loop->stop;
  });

=head1 DESCRIPTION

C<Linux::Event::Signal> adapts signalfd-style signal delivery into the reactor
loop. Most users access it through C<< $loop->signal(...) >> rather than
constructing it directly.

Signal subscriptions are loop primitives. They are not a general-purpose signal
framework.

=head1 CALLBACK ABI

Signal callbacks receive four arguments:

  $cb->($loop, $signal_name, $count, $data)

C<$count> is the number of queued deliveries drained in the current dispatch.

=head1 SUBSCRIPTIONS

The returned subscription object supports C<cancel>.

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Loop>

=cut
