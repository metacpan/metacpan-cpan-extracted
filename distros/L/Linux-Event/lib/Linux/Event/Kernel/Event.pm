package Linux::Event::Kernel::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

use Carp qw(croak);
use Config ();
use Scalar::Util qw(refaddr weaken);

require Linux::Event::Loop;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my %CLASS_DESCRIPTOR;
my %OWNER_STATE;
my %LIVE_HANDLE;
my $NEXT_ID = 1;
my $MAX_INCREMENT = $Config::Config{uvsize} >= 8
    ? '18446744073709551614' : '4294967295';

sub _decimal_greater_than ($value, $maximum) {
    $value =~ s/\A0+//;
    $value = '0' if $value eq '';
    return 1 if length($value) > length($maximum);
    return 0 if length($value) < length($maximum);
    return $value gt $maximum;
}

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Event subclass"
        if !$class->isa(__PACKAGE__);
    my $callback = $class->can('on_event')
        // croak "$class must define on_event() or receive on_event => coderef";
    return $CLASS_DESCRIPTOR{$class} = { callback => $callback };
}

sub _effective_descriptor ($class, $option) {
    croak "$class is not a Linux::Event::Kernel::Event subclass"
        if !$class->isa(__PACKAGE__);
    return _descriptor_for($class) if !exists $option->{on_event};
    my $callback = delete $option->{on_event};
    croak 'new(): on_event must be a coderef' if ref($callback) ne 'CODE';
    return { callback => $callback };
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    my $id = $NEXT_ID++;
    my $self = bless {
        id              => $id,
        fd              => _new_fd(),
        terminal        => 0,
        owner_pid       => $$,
        owner_interpreter => _interpreter_id(),
        handle_interpreter => _interpreter_id(),
        cloned_signal_handle => 0,
    }, $class;
    $LIVE_HANDLE{$id} = $self;
    weaken($LIVE_HANDLE{$id});
    $OWNER_STATE{$id} = bless {
        descriptor => $descriptor,
        loop       => undef,
        watcher    => undef,
        data       => $data,
        state      => 'unattached',
    }, 'Linux::Event::Kernel::Event::_OwnerState';
    $loop->add($self) if defined $loop;
    return $self;
}

sub _assert_owner ($self, $method) {
    croak "$method(): Event may be managed only by its creating interpreter"
        if $self->{cloned_signal_handle}
        || $self->{owner_pid} != $$
        || $self->{owner_interpreter} != _interpreter_id();
    return;
}

sub _owner_state ($self, $method) {
    $self->_assert_owner($method);
    return $OWNER_STATE{ $self->{id} }
        // croak "$method(): Event owner state is unavailable";
}

sub _attach_to_loop ($self, $loop) {
    croak 'add(): Event is not unattached' if $self->{terminal};
    my $state = $self->_owner_state('add');
    croak 'add(): Event is not unattached'
        if $state->{state} ne 'unattached' || $state->{loop};
    my $watcher = $loop->watch(
        fd      => $self->{fd},
        _internal => 1,
        read    => sub { $self->_dispatch },
        error   => sub { die "Linux::Event Event event source failed\n" },
        no_args => 1,
        lean    => 1,
    );
    $state->{loop} = $loop;
    $state->{state} = 'active';
    $state->{watcher} = $watcher;
    return $self;
}

sub _dispatch ($self) {
    my $state = $self->_owner_state('dispatch');
    return if $state->{state} ne 'active';
    my $count = _drain_fd($self->{fd});
    return if !$count;
    $state->{descriptor}{callback}->($self, $count);
    return;
}

sub signal ($self, $increment = 1) {
    croak 'signal(): Event is cancelled' if $self->{terminal};
    croak 'signal(): cloned Event handle belongs to another interpreter'
        if $self->{handle_interpreter} != _interpreter_id();
    croak 'signal(): increment must be a positive integer'
        if !defined($increment) || ref($increment)
        || $increment !~ /\A\d+\z/ || $increment == 0;
    croak 'signal(): increment exceeds the supported eventfd range'
        if _decimal_greater_than("$increment", $MAX_INCREMENT);
    _signal_fd($self->{fd}, 0 + $increment);
    return $self;
}

sub cancel ($self) {
    return $self if $self->{terminal};
    my $state = $self->_owner_state('cancel');
    $state->{watcher}->cancel if $state->{watcher};
    $state->{watcher} = undef;
    _close_fd(delete $self->{fd}) if defined $self->{fd};
    delete $LIVE_HANDLE{ $self->{id} };
    $state->{loop} = undef;
    $state->{data} = undef;
    $state->{state} = 'cancelled';
    delete $OWNER_STATE{ $self->{id} };
    $self->{terminal} = 1;
    return $self;
}

sub loop ($self) {
    return undef if $self->{terminal};
    return $self->_owner_state('loop')->{loop};
}
sub state ($self) {
    return 'cancelled' if $self->{terminal};
    return $self->_owner_state('state')->{state};
}
sub is_active ($self) { $self->state eq 'active' }
sub is_terminal ($self) { !!$self->{terminal} }

sub data ($self, @argument) {
    croak 'data(): Event is cancelled' if $self->{terminal};
    my $state = $self->_owner_state('data');
    $state->{data} = $argument[0] if @argument;
    return $state->{data};
}

sub _objects_for_loop ($class, $loop) {
    my @object;
    for my $id (keys %LIVE_HANDLE) {
        my $object = $LIVE_HANDLE{$id} // next;
        next if $object->{terminal};
        my $state = $OWNER_STATE{$id} // next;
        next if !$state->{loop}
            || refaddr($state->{loop}) != refaddr($loop);
        push @object, $object;
    }
    return \@object;
}

sub CLONE ($class) {
    for my $id (keys %LIVE_HANDLE) {
        my $self = $LIVE_HANDLE{$id};
        if (!$self) {
            delete $LIVE_HANDLE{$id};
            next;
        }
        next if $self->{terminal} || !defined $self->{fd};
        $self->{fd} = _dup_fd($self->{fd});
        $self->{handle_interpreter} = _interpreter_id();
        $self->{cloned_signal_handle} = 1;
    }
    return;
}

sub DESTROY ($self) {
    my $interpreter = eval { _interpreter_id() };
    my $is_owner = !$self->{cloned_signal_handle}
        && defined($interpreter)
        && $self->{owner_pid} == $$
        && $self->{owner_interpreter} == $interpreter;
    if ($is_owner) {
        my $state = delete $OWNER_STATE{ $self->{id} };
        eval { $state->{watcher}->cancel if $state && $state->{watcher}; 1 };
    }
    my $live = $LIVE_HANDLE{ $self->{id} };
    delete $LIVE_HANDLE{ $self->{id} }
        if !$live || refaddr($live) == refaddr($self);
    return if !defined($interpreter)
        || $self->{handle_interpreter} != $interpreter;
    eval { _close_fd(delete $self->{fd}); 1 } if defined $self->{fd};
    return;
}

package Linux::Event::Kernel::Event::_OwnerState;
use v5.36;
use strict;
use warnings;

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Event;

1;
__END__

=head1 NAME

Linux::Event::Kernel::Event - eventfd-backed Loop notification

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Event;

  my $loop = Linux::Event::Loop->new;
  my $notifications = 0;
  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,
      on_event => sub ($event, $count) {
          $notifications += $count;
          $event->loop->stop;
      },
  );

  # From a worker thread, native extension, or forked child:
  $event->signal;
  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Event> is the public eventfd notification leaf. It lets
another execution context make the owning Loop runnable without pretending that
an eventfd transports arbitrary Perl values or callbacks.

The eventfd carries a 64-bit counter. Application payloads belong in an
appropriate queue, shared native structure, pipe, socket, or other IPC channel.
Publish the payload first, then call C<signal>.

=head1 CALLBACKS AND SUBCLASS POLICY

C<on_event =E<gt> sub ($event, $count) { ... }> may be passed directly to
C<new>. This closure form is usually best for one object because it can capture
lexical application state. A constructor callback overrides a same-named
subclass method for that object.

A subclass method remains useful when many Event objects share named,
testable behavior:

  package ResultsReady;
  use parent 'Linux::Event::Kernel::Event';

  sub on_event ($event, $count) {
      drain_results($event->data, $count);
  }

Linux::Event resolves the method once per subclass or retains the constructor
closure once per object. Delivery uses the resulting cached CV; it does not
perform a method lookup or choose between the two forms for every event.

=head1 CONSTRUCTION AND CALLBACK

A subclass may define, or C<new> may receive:

  sub on_event ($event, $count) { ... }

C<data> typically contains the application-owned queue or state associated with
the notification. C<loop =E<gt> $loop> attaches immediately; otherwise add the
detached object with C<< $loop->add($event) >>.

C<$count> is the counter value drained from eventfd. Multiple producer writes
may coalesce into one callback, so the payload channel rather than C<$count> is
the source of truth for individual work items.

=head1 SIGNALING

C<signal> writes one to the counter. C<signal($increment)> adds an explicit
positive increment and returns the Event object. Signaling never invokes
C<on_event> inline; delivery occurs on the owning Loop thread.

The eventfd is nonblocking and close-on-exec. Counter saturation is reported as
a kernel write failure rather than discarding existing readiness.

=head1 THREAD AND FORK BOUNDARY

Linux::Event does not require a threaded Perl. Event is useful for native worker
threads, external libraries, and forked processes as well as Perl ithreads.

On an ithread-enabled Perl, a cloned Event handle may signal only. It cannot
manage the Loop, callback, or owner data. The clone uses its own descriptor
duplicate so destruction or descriptor reuse in one interpreter cannot corrupt
another.

A forked child may signal the inherited eventfd until exec. Cross-process
payloads still require real IPC or shared storage.

=head1 LIFECYCLE

C<cancel> is idempotent and terminal. It removes the Loop registration and
releases owner-side state. Callback exceptions propagate through ordinary Loop
dispatch and do not silently cancel the Event.

The native eventfd extension dispatches C<on_event> directly.

=head1 SEE ALSO

L<Linux::Event::Loop>, F<docs/EVENT-DESIGN.md>.

=cut
