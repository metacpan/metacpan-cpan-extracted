package Gearman::Task;
use version;
$Gearman::Task::VERSION = version->declare("2.004.015");

use strict;
use warnings;

=head1 NAME

Gearman::Task - a task in Gearman, from the point of view of a client

=head1 SYNOPSIS

    my $task = Gearman::Task->new("add", "1+2", {
            ...
    });

    $taskset->add_task($task);
    $client->do_task($task);
    $client->dispatch_background($task);


=head1 DESCRIPTION

I<Gearman::Task> is a Gearman::Client's representation of a task to be
done.

=head1 USAGE

=head2 Gearman::Task->new($func, $arg, \%options)

Creates a new I<Gearman::Task> object, and returns the object.

I<$func> is the function name to be run.  (that you have a worker registered to process)

I<$arg> is an opaque scalar or scalarref representing the argument(s)
to pass to the distributed function.  If you want to pass multiple
arguments, you must encode them somehow into this one.  That's up to
you and your worker.

I<%options> can contain:

=over 4

=item

uniq

A key which indicates to the server that other tasks with the same
function name and key will be merged into one.  That is, the task
will be run just once, but all the listeners waiting on that job
will get the response multiplexed back to them.

Uniq may also contain the magic value "-" (a single hyphen) which
means the uniq key is the contents of the args.

=item

on_complete

A subroutine reference to be invoked when the task is completed. The
subroutine will be passed a reference to the return value from the worker
process.

=item

on_fail

A subroutine reference to be invoked when the task fails (or fails for
the last time, if retries were specified). The reason could be passed
to this callback as an argument. This callback won't be called after a
failure if more retries are still possible.

=item

on_retry

A subroutine reference to be invoked when the task fails, but is about
to be retried.

Is passed one argument, what retry attempt number this is.  (starts with 1)

=item

on_status

A subroutine reference to be invoked if the task emits status updates.
Arguments passed to the subref are ($numerator, $denominator), where those
are left up to the client and job to determine.

=item

on_warning

A subroutine reference to be invoked if the task emits status updates.
Arguments passed to the subref are ($numerator, $denominator), where those
are left up to the client and job to determine.

=item

retry_count

Number of times job will be retried if there are failures.  Defaults to 0.

=item

high_priority

B<the option high_priority is deprecated>. Use C<< priority => high >> instead.
Boolean, whether this job should take priority over other jobs already
enqueued.

=item

priority

valid value:

=over

=item

high

=item

normal (defaul)

=item

low

=back

=item

timeout

Automatically fail, calling your on_fail callback, after this many
seconds have elapsed without an on_fail or on_complete being
called. Defaults to 0, which means never.  Bypasses any retry_count
remaining.

=item

try_timeout

Automatically fail, calling your on_retry callback (or on_fail if out of
retries), after this many seconds have elapsed. Defaults to 0, which means
never.

=back

=cut

use Carp          ();
use Gearman::Util ();
use Scalar::Util  ();
use String::CRC32 ();
use Storable      ();

use fields (

    # from client:
    'func',
    'argref',

    # opts from client:
    'uniq',
    'on_complete',
    'on_data',
    'on_fail',
    'on_exception',
    'on_warning',
    'on_retry',
    'on_status',
    'on_post_hooks',

    # used internally,
    # when other hooks are done running,
    # prior to cleanup
    'retry_count',
    'timeout',
    'try_timeout',
    'high_priority',
    'background',

    # from server:
    'handle',

    # maintained by this module:
    'retries_done',
    'is_finished',
    'taskset',

    # jobserver socket.
    # shared by other tasks in the same taskset,
    # but not w/ tasks in other tasksets using
    # the same Gearman::Client
    'jssock',

    # hookname -> coderef
    'hooks',
    'priority',
);

# constructor, given: ($func, $argref, $opts);
sub new {
    my $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }

    $self->{func} = shift
        or Carp::croak("No function given");

    $self->{argref} = shift || do { my $empty = ""; \$empty; };
    (ref $self->{argref} eq "SCALAR")
        || Carp::croak("Argref not a scalar reference");

    my $opts = shift || {};

    $self->{$_} = delete $opts->{$_} for qw/
        background
        high_priority
        on_complete
        on_data
        on_exception
        on_fail
        on_retry
        on_status
        on_warning
        retry_count
        timeout
        try_timeout
        uniq
        /;

    $self->_priority(delete $opts->{priority});

    $self->{retry_count} ||= 0;

    # bool: if success or fail has been called yet on this.
    $self->{is_finished} = 0;

    if (%{$opts}) {
        Carp::croak("Unknown option(s): " . join(", ", sort keys %$opts));
    }

    $self->{retries_done} = 0;

    return $self;
} ## end sub new

#=head1 METHODS
#
#=head2 run_hook($name)
#
#run a hook callback if defined
#
#=cut

sub run_hook {
    my ($self, $name) = (shift, shift);
    ($name && $self->{hooks}->{$name}) || return;

    eval { $self->{hooks}->{$name}->(@_) };
    warn "Gearman::Task hook '$name' threw error: $@\n" if $@;
} ## end sub run_hook

#=head2 add_hook($name, $cb)
#
#add a hook
#
#=cut

sub add_hook {
    my ($self, $name) = (shift, shift);
    $name || return;

    if (@_) {
        $self->{hooks}->{$name} = shift;
    }
    else {
        delete $self->{hooks}->{$name};
    }
} ## end sub add_hook

#=head2 is_finished()
#
#B<return> bool: whether or not task is totally done (on_failure or
#on_complete callback has been called)
#
#=cut

sub is_finished {
    return shift->{is_finished};
}

#=head2 taskset()
#
#getter
#
#=head2 taskset($ts)
#
#setter
#
#B<return> Gearman::Taskset
#
#=cut

sub taskset {
    my $self = shift;

    # getter
    return $self->{taskset} unless @_;

    # setter
    my $ts = shift;
    (Scalar::Util::blessed($ts) && $ts->isa("Gearman::Taskset"))
        || Carp::croak("argument is not an instance of Gearman::Taskset");
    $self->{taskset} = $ts;

    if (my $hash_num = $self->hash()) {
        $self->{jssock} = $ts->_get_hashed_sock($hash_num);
    }
    else {
        $self->{jssock} = $ts->_get_default_sock;
    }

    return $self->{taskset};
} ## end sub taskset

#=head2 hash()
#
#B<return> undef on non-uniq packet, or the hash value (0-32767) if uniq
#
#=cut

sub hash {
    my $self     = shift;
    my $merge_on = $self->{uniq}
        && $self->{uniq} eq "-" ? $self->{argref} : \$self->{uniq};
    if (${$merge_on}) {
        return (String::CRC32::crc32(${$merge_on}) >> 16) & 0x7fff;
    }
    else {
        return;
    }
} ## end sub hash

#=head2 pack_submit_packet([$client])
#
#B<return> Gearman::Util::pack_req_command(mode, func, uniq, argref)
#
#=cut

sub pack_submit_packet {
    my ($self, $client) = @_;

    # $client should be optional for sake of Gearman::Client::Async
    # see https://github.com/p-alik/perl-Gearman/issues/10
    my $func = $client ? $client->func($self->func) : $self->func;

    return Gearman::Util::pack_req_command(
        $self->mode,
        join(
            "\0", $func || '', $self->{uniq} || '', ${ $self->{argref} } || ''
        )
    );
} ## end sub pack_submit_packet

#=head2 fail($reason)
#
#=cut

sub fail {
    my ($self, $reason) = @_;
    return if $self->{is_finished};

    # try to retry, if we can
    if ($self->{retries_done} < $self->{retry_count}) {
        $self->{retries_done}++;
        $self->{on_retry}->($self->{retries_done}) if $self->{on_retry};
        $self->handle(undef);
        return $self->{taskset}->add_task($self);
    } ## end if ($self->{retries_done...})

    $self->final_fail($reason);
} ## end sub fail

#=head2 final_fail($reason)
#
#if C<< !is_finished >> runs the hooks
#
#=over
#
#=item
#
#on_fail
#
#=item
#
#on_post_hooks
#
#=back
#
#=cut

sub final_fail {
  my ($self, $reason) = @_;

  return if $self->{is_finished};
    $self->{is_finished} = $reason || 1;

    $self->run_hook('final_fail', $self);

    $self->{on_fail}->($reason) if $self->{on_fail};
    $self->{on_post_hooks}->()  if $self->{on_post_hooks};
    $self->wipe;

    return;
} ## end sub final_fail

#=head2 exception($exc_ref)
#
#$exc_ref may be a Storable serialized value
#
#run on_exception if defined
#
#=cut

sub exception {
    my ($self, $exc_ref) = @_;

    #FIXME the only on_exception callback get dereferenced value
    # could it be changed without damage?
    my $exception = Storable::thaw($$exc_ref);
    $self->{on_exception}->($$exception) if $self->{on_exception};
    return;
} ## end sub exception

#=head2 complete($result)
#
#C<$result> a reference profided to on_complete cb
#
#=cut

sub complete {
    my ($self, $result_ref) = @_;
    return if $self->{is_finished};

    $self->{is_finished} = 'complete';

    $self->run_hook('complete', $self);

    $self->{on_complete}->($result_ref) if $self->{on_complete};
    $self->{on_post_hooks}->() if $self->{on_post_hooks};
    $self->wipe;
} ## end sub complete

#=head2 status()
#
#=cut

sub status {
    my $self = shift;
    return if $self->{is_finished};
    return unless $self->{on_status};
    my ($nu, $de) = @_;
    $self->{on_status}->($nu, $de);
} ## end sub status

#=head2 data()
#
#invokes C<on_data> callback if worker sends work_data notification.
#
#=cut

sub data {
    my $self = shift;
    return if $self->{is_finished};
    my $result_ref = shift;

    $self->{on_data}->($result_ref) if $self->{on_data};
} ## end sub data

#=head2 warning($message)
#
#invokes C<on_warning> callback if worker sends work_warning notification.
#
#=cut

sub warning {
    my $self = shift;
    $self->{is_finished} && return;
    $self->{on_warning} || return;

    my $msg = shift;

    $self->{on_warning}->($msg);
} ## end sub warning

#=head2 handle()
#
#getter
#
#=head2 handle($handle)
#
#setter for the fully-qualified handle of form "IP:port//shandle" where
#
#shandle is an opaque handle specific to the job server running on IP:port
#
#=cut

sub handle {
    my $self = shift;
    if (@_) {
        $self->{handle} = shift;
    }
    return $self->{handle};
} ## end sub handle


# Gearman::Client::Async is the only consumer of set_on_post_hooks
sub set_on_post_hooks {
    my ($self, $code) = @_;
    $self->{on_post_hooks} = $code;
}

#=head2 wipe()
#
#cleanup
#
#=over
#
#=item
#
#on_post_hooks
#
#=item
#
#on_complete
#
#=item
#
#on_fail
#
#=item
#
#on_retry
#
#=item
#
#on_status
#
#=item
#
#hooks
#
#=back
#
#=cut

sub wipe {
    my $self = shift;
    my @h    = qw/
        on_post_hooks
        on_complete
        on_fail
        on_retry
        on_status
        hooks
        /;

    foreach my $f (@h) {
        $self->{$f} = undef;
    }
} ## end sub wipe

#=head2 func()
#
#=cut

sub func {
    my $self = shift;
    return $self->{func};
}

#=head2 timeout()
#
#getter
#
#=head2 timeout($t)
#
#setter
#
#B<return> timeout
#
#=cut

sub timeout {
    my $self = shift;
    if (@_) {
        $self->{timeout} = shift;
    }
    return $self->{timeout};
} ## end sub timeout

#=head2 mode()
#
#B<return> mode in depends of background and priority
#
#=cut

sub mode {
    my $self = shift;
    my $mode = "submit_job";
    if ($self->_priority() ne "normal") {
        $mode .= "_" . $self->_priority();
    }

    if ($self->{background}) {
        $mode .= "_bg";
    }

    return $mode;
} ## end sub mode

#=head2 _priority($priority)
#
#set/get priority
#
#valid C<$priority> value
#
#=over
#
#=item
#
#high
#
#=item
#
#normal (default)
#
#=item
#
#low
#
#=back
#
#=cut

sub _priority {
    my ($self, $priority) = @_;
    if ($self->{high_priority}) {
        warn <<'HERE';
Gearman::Task key high_priority is deprecated.
Use priority => "high" instead
HERE
        $self->{priority} = "high";
        delete($self->{high_priority});
    } ## end if ($self->{high_priority...})

    if ($priority) {
        $priority =~ /^(high|normal|low)$/
            || Carp::croak "unsupported priority value";
        $self->{priority} = $priority;
    }
    $self->{priority} ||= "normal";

    return $self->{priority};
} ## end sub _priority

1;
__END__

