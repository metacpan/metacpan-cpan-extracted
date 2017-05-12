package Forks::Queue;
use strict;
use warnings;
use Scalar::Util 'looks_like_number';
use Carp;
use Time::HiRes;
use Config;

our $VERSION = '0.06';
our $DEBUG = $ENV{FORKS_QUEUE_DEBUG} || 0;

our $NOTIFY_OK = $ENV{FORKS_QUEUE_NOTIFY} // do {
    $Config::Config{sig_name} =~ /\bIO\b/;
    1;
};
our $SLEEP_INTERVAL = $NOTIFY_OK ? 2 : 1;
our $SLEEP_INTERVALX = 2;

# default values to apply to all new Forks::Queue implementations
our %OPTS = (limit => -1, on_limit => 'fail', style => 'fifo',
             impl => $ENV{FORKS_QUEUE_IMPL} || 'File' );

sub new {
    my $pkg = shift;
    my %opts = (%OPTS, @_);

    if ($opts{impl}) {
        $pkg = delete $opts{impl};
        if ($pkg =~ /[^\w:]/) {
            croak "Forks::Queue cannot be instantiated. Invalid 'impl' $pkg";
        }
        if (eval "require Forks::Queue::$pkg; 1") {
            $pkg = "Forks::Queue::" . $pkg;
            return $pkg->new(%opts);
        } elsif (eval "require $pkg; 1") {
            return $pkg->new(%opts);
        } else {
            croak "Forks::Queue cannot be instantiated. ",
                "Did not recognize 'impl' option '$opts{impl}'";
        }
    }
    croak "Forks::Queue cannot be instantiated. ",
        "Use an implementation or pass the 'impl' option to the constructor";
}

sub import {
    my ($class, @args) = @_;
    for (my $i=0; $i<@args; $i++) {
        foreach my $key (qw(limit on_limit impl style)) {
            if ($args[$i] eq $key) {
                $OPTS{$args[$i]} = $args[$i+1];
                $i++;
                next;
            }
        }
    }
}

sub put {
    my $self = CORE::shift;
    return $self->push(@_);
}

sub enqueue { goto &put; }

sub get {
    my $self = CORE::shift;
    _validate_input($_[0], 'count', 1) if @_;
    if ($self->{style} eq 'fifo') {
        return @_ ? $self->shift(@_) : $self->shift;
    } else {
        my @gotten = @_ ? reverse($self->pop(@_)) : $self->pop;
        return @_ ? @gotten : $gotten[0];
    }
}

sub dequeue { goto &get; }

sub dequeue_timed {
    my $self = CORE::shift;
    my $timeout = CORE::shift;
    _validate_input($timeout, 'timeout', 0, 1);
    local $self->{_expire} = Time::HiRes::time + $timeout;
    local $SLEEP_INTERVAL = $Forks::Queue::SLEEP_INTERVAL;
    $SLEEP_INTERVAL /= 2 while $SLEEP_INTERVAL > 0.25 * $timeout;
    return @_ ? $self->dequeue(@_) : $self->dequeue;
}

sub get_timed {
    my $self = CORE::shift;
    my $timeout = CORE::shift;
    _validate_input($timeout, 'timeout', 0, 1);
    local $self->{_expire} = Time::HiRes::time + $timeout;
    local $SLEEP_INTERVAL = $Forks::Queue::SLEEP_INTERVAL;
    $SLEEP_INTERVAL /= 2 while $SLEEP_INTERVAL > 0.25 * $timeout;
    return @_ ? $self->get(@_) : $self->get;
}

sub shift_timed {
    my $self = CORE::shift;
    my $timeout = CORE::shift;
    _validate_input($timeout, 'timeout', 0, 1);
    local $self->{_expire} = Time::HiRes::time + $timeout;
    local $SLEEP_INTERVAL = $Forks::Queue::SLEEP_INTERVAL;
    $SLEEP_INTERVAL /= 2 while $SLEEP_INTERVAL > 0.25 * $timeout;
    return @_ ? $self->shift(@_) : $self->shift;
}

sub pop_timed {
    my $self = CORE::shift;
    my $timeout = CORE::shift;
    _validate_input($timeout, 'timeout', 0, 1);
    local $self->{_expire} = Time::HiRes::time + $timeout;
    local $SLEEP_INTERVAL = $Forks::Queue::SLEEP_INTERVAL;
    $SLEEP_INTERVAL /= 2 while $SLEEP_INTERVAL > 0.25 * $timeout;
    return @_ ? $self->pop(@_) : $self->pop;
}

sub _expired {
    my ($self) = @_;
    $self->{_expire} && Time::HiRes::time >= $self->{_expire};
}

sub get_nb {
    my $self = CORE::shift;
    _validate_input($_[0], 'count', 1) if @_;
    if ($self->{style} eq 'fifo') {
        return @_ ? $self->shift_nb(@_) : $self->shift_nb;
    } else {
        return @_ ? @ := reverse($self->pop_nb(@_)) : $self->pop_nb;
    }
}
sub dequeue_nb { goto &get_nb; }

sub peek {
    my ($self,$index) = @_;
    _validate_input($index, 'index') if @_ > 1;
    if ($self->{style} eq 'lifo') {
        return $self->peek_back($index || 0);
    } else {
        return $self->peek_front($index || 0);
    }
}

sub pending {
    my $self = CORE::shift;
    my $s = $self->status;
    return $s->{avail} ? $s->{avail} : $s->{end} ? undef : 0;
}

sub _croak {
    my $func = shift;
    croak "Forks::Queue: $func not implemented in abstract base class";
}

sub limit :lvalue {
    my $self = shift;
    if (@_) {
        $self->{limit} = CORE::shift @_;
        if (@_) {
            $self->{on_limit} = CORE::shift @_;
        }
    }
    $self->{limit};
}

sub _validate_input {
    my ($value,$name,$ge,$float_ok) = @_;
    croak "Invalid '$name'"
        if !defined($value) ||
        !looks_like_number($value) ||
        (!$float_ok && $value != int($value)) ||
        (defined($ge) && $value < $ge);
    return $value;
}

sub push       { _croak("push/put") }
sub peek_front { _croak("peek") }
sub peek_back  { _croak("peek") }
sub shift      { _croak("shift/get") }
sub unshift    { _croak("unshift") }
sub pop        { _croak("pop/get") }
sub shift_nb   { _croak("shift/get") }
sub pop_nb     { _croak("pop/get") }
sub status     { _croak("pending/status") }
sub clear      { _croak("clear") }

1;

=head1 NAME

Forks::Queue - queue that can be shared across processes

=head1 VERSION

0.06

=head1 SYNOPSIS

  use Forks::Queue;
  $q = Forks::Queue->new( impl => ..., style => 'lifo' );

  # put items on queue
  $q->put("a scalar item");
  $q->put(["an","arrayref","item"]);
  $q->put({"a"=>"hash","reference"=>"item"});
  $q->put("list","of","multiple",["items"]);
  $q->end;        # no more jobs will be added to queue

  # retrieve items from queue, possibly after a fork
  $item = $q->get;
  $item = $q->peek;      # get item without removing it
  @up_to_10_items = $q->get(10);
  $remaining_items = $q->pending;

=head1 DESCRIPTION

Interface for a queue object that can be shared across processes
and threads. 
Available implementations are L<Forks::Queue::File|Forks::Queue::File>,
L<Forks::Queue::Shmem|Forks::Queue::Shmem>,
L<Forks::Queue::SQLite|Forks::Queue::SQLite>.

=head1 METHODS

Many of these methods pass or return "items". For this distribution,
an "item" is any scalar or reference that can be serialized and
shared across processes.

This will include scalars and most unblessed references

  "42"
  [1,2,3,"forty-two"]
  { name=>"a job", timestamp=>time, input=>{foo=>[19],bar=>\%bardata} }

but will generally preclude data with blessed references and code references

  { name => "bad job", callback => \&my_callback_routine }
  [ 46, $url13, File::Temp->new ]

=head2 new

=head2 $queue = Forks::Queue->new( %opts )

Instantiates a new queue object with the given configuration.

If one of the options is C<impl>, the constructor from that
C<Forks::Queue> subclass will be invoked.

Other options that should be supported on all implementations include

=over 4

=item * C<< style => 'fifo' | 'lifo' >>

Indicates whether the L<"get"> method will return items in
first-in-first-out order or last-in-first-out order (and which
end of the queue the L<"peek"> method will examine)

=item * C<< limit => int >>

A maximum size for the queue. Set to a non-positive value to
specify an unlimited size queue.

=item * C<< on_limit => 'block' | 'fail' >>

Dictates what the queue should do when an attempt is made to
add items beyond the queue's limit. If C<block>, the queue
will block and wait until items are removed from the queue.
If C<fail>, the queue will warn and return immediately without
changing the queue.

See the L<"enqueue">, L<"put">, L<"push">, L<"unshift">,
and L<"insert"> methods, which are used to increase the length
of the queue and may be affected by this setting.

=item * C<< join => bool >>

If true, expects that the queue referred to by this constructor
has already been created in another process, and that the current
process should access the existing queue. This allows a queue to
be shared across unrelated processes (i.e., processes that do not
have a parent-child relationship).

  # my_daemon.pl - may run "all the time" in the background
  $q = Forks::Queue::File->new(file=>'/var/spool/foo/q17');
  # creates new queue object
  ... 

  # worker.pl - may run periodically for a short time, launched from
  #             cron or from command line, but not from the daemon
  $q = Forks::Queue->new( impl => 'File', join => 1,
                          file => '/var/spool/foo/q17',
  # the new queue attaches to existing file at /var/spool/foo/q17
  ...

C<join> is not necessary for child processes forked from a process with
an existing queue

  $q = Forks::Queue->new(...)
  ...
  if (fork() == 0) {
      # $q already exists and the child process can begin using it,
      # no need for a  Forks::Queue  constructor with  join
      ...
  }

=item * C<< persist => bool >>

Active C<Forks::Queue> objects affect your system, writing to disk or
writing to memory, and in general they clean themselves up when they
detect that no more processes are using the queue. The C<persist> option,
if set to true, instructs the queue object to leave its state intact
after destruction.

An obvious use case for this option is debugging, to examine the
state of the queue after abnormal termination of your program.

A second use case is to create persistent queues -- queues that are
shared not only among different processes, but among different 
processes that are running at different times. The persistent queue
can be used by supplying both the C<persist> and the C<join> options
to the C<Forks::Queue> constructor.

    $queue_file = "/tmp/persistent.job.queue";
    $join = -f $queue_file;
    $q = Forks::Queue->new( impl => 'File', file => $queue_file,
                            join => $join, persist => 1 );
    ... work with the queue ...
    # the queue remains intact if this program exits or aborts

=item * C<< list => ARRAYREF >>

Initializes the contents of the queue with the argument to the
C<list> option. The argument must be an array reference.

If the C<join> option is specified, the contents of the list
could be added to an already existing queue.

=back

See the global L<"%OPTS"/"%OPTS"> variable for information about
default values for many of these settings.

=head2 put

=head2 enqueue

=head2 $count = $queue->put(@items); $count = $queue->enqueue(@items)

Place one or more "items" on the queue, and returns the number of
items successfully added to the queue.

Adding items to the queue will fail if the L<"end"> method of
the queue had previously been called from any process.

The C<enqueue> method name is provided for compatibility with
L<Thread::Queue|Thread::Queue>.

See the L<"limit"> method to see how the C<put> method behaves
when adding items would cause the queue to exceed its maximum size.


=head2 push

=head2 $count = $queue->push(@items)

Equivalent to L<"put">, adding items to the end of the queue and
returning the number of items successfully added. The most recent
items appended to the queue by C<push> or C<put> will be the first
items taken from the queue by L<"pop"> or by L<"get"> with LIFO
style queues, and the last items removed by L<"shift"> or L<"get">
with FIFO style queues.

If the items added to the queue would cause the queue to exceed
its queue size limit (as determined by the L<"limit"> attribute),
this method will either block until queue capacity is available,
or issue a warning about the uninserted items and return the
number of items added, depending on the queue's setting for
L<"on_limit"|Forks::Queue/"new">.


=head2 unshift

=head2 $count = $queue->unshift(@items)

Equivalent to C<insert(0,@items)>, adding items to the front
of the queue, and returning the number of items successfully
added. In FIFO queues, items added to the queue with C<unshift>
will be the last items taken from the queue by L<"get">,
and in LIFO queues, they will be the first items taken from the
queue by L<"get">.

This method is inefficient for some queue implementations.

=head2 end

=head2 $queue->end

Indicates that no more items are to be put on the queue,
so that when a process tries to retrieve an item from an empty queue,
it will not block and wait until a new item is added. Causes any
processes blocking on a L<"get">/L<"dequeue">/L<"shift">/L<"pop">
call to become unblocked and return C<undef>.
This method may be called from any process that has access to the queue.


=head2 get

=head2 dequeue

=head2 $item = $queue->get; $item = $queue->dequeue;

=head2 @items = $queue->get($count); @items = $queue->dequeue($count);

Attempt to retrieve one or more "items" on the queue. If the
queue is empty, and if L<"end"> has not been called on the queue,
this call blocks until an item is available or until the L<"end">
method has been called from some other process. If the queue is
empty and L<"end"> has been called, this method returns an
empty list in list context or C<undef> in scalar context.

If a C<$count> argument is supplied, returns up to C<$count> items
or however many items are currently availble on the queue, whichever
is fewer. But the call still blocks if L<"end"> has not been called
until there is at least one item available. See L<"get_nb"> for a
non-blocking version of this method. The return value of this
function when a C<$count> argument is supplied is always a list,
so if you evaluate it in scalar context you will get the number of items
retrieved from the queue, not the items themselves.

  $job = $q->get;         # $job is an item from the queue
  $job = $q->get(1);      # returns # of items retrieved, not an actual item!
  ($job) = $q->get(1);    # $job is an item from the queue

The only important difference between C<get> and C<dequeue> is what
happens when there is a C<$count> argument, and the queue currently has
more than zero but less than C<$count> items available. In this case,
the C<get> call will return all of the available items. The C<dequeue>
method will block until at least C<$count> items are available on the
queue, or until the L<"end"> method has been called on the queue.
This C<dequeue> behavior is consistent with the behavior of the 
L<"dequeue" method in Thread::Queue|Thread::Queue/"dequeue">.


=head2 pop

=head2 $item = $queue->pop

=head2 @items = $queue->pop($count)

Retrieves one or more items from the "back" of the queue.
For LIFO style queues, the L<"get"> method is equivalent to this method.
Like C<"get">, this method blocks while the queue is empty and the
L<"end"> method has not been called on the queue.

If a C<$count> argument is supplied, returns up to C<$count> items or however
many items are currently available on the queue, whichever is fewer.
(Like the L<"get"> call, this method blocks when waiting for input. See
L<"pop_nb"> for a non-blocking version of the method. Also like
L<"get">, you should be wary of using this method in scalar context
if you provide a C<$count> argument).

=head2 shift

=head2 $item = $queue->shift

=head2 @items = $queue->shift($count)

Retrieves one or more items from the "front" of the queue.
For FIFO style queues, the L<"get"> method is equivalent to this method.
Like C<"get">, this method blocks while the queue is empty and the
L<"end"> method has not been called on the queue.

If a C<$count> argument is supplied, returns up to C<$count> items or however
many items are currently available on the queue, whichever is fewer. (Like the 
L<"get"> call, this method blocks when waiting for input. See
L<"shift_nb"> for a non-blocking version of the method. Also like
L<"get">, you should be wary of using this method in scalar context
if you provide a C<$count> argument).


=head2 get_nb

=head2 dequeue_nb

=head2 pop_nb

=head2 shift_nb

=head2 $item = $queue->XXX_nb

=head2 @items = $queue->XXX_nb($count)

Non-blocking versions of the L<"get">, L<"dequeue">, L<"pop">,
and L<"shift"> methods. These functions return immediately if
there are no items in the queue to retrieve, returning C<undef>
in the case with no arguments and an empty list when a
C<$count> argument is supplied.

=head2 get_timed

=head2 dequeue_timed

=head2 shift_timed

=head2 pop_timed

=head2 $item = $queue->XXX_timed($timeout)

=head2 @item = $queue->XXX_timed($timeout,$count)

Timed versions of L<"get">, L<"dequeue">, L<"shift">, and L<"pop">
that take a C<$timeout> argument and will stop blocking after
C<$timeout> seconds have elapsed.

If a C<$count> argument is supplied to C<dequeue_timed>, the function
will wait up to C<$timeout> seconds for at least C<$count> items to
be available on the queue. After C<$timeout> seconds have passed,
the function will return up to C<$count> available items.

For other timed methods, supplying a C<$count> argument for a
queue with more than zero but less than C<$count> items available
will return all available items without blocking.


=head2 peek

=head2 $item = $queue->peek

=head2 $item = $queue->peek($index)

=head2 $item = $queue->peek_front

=head2 $item = $queue->peek_back

Returns an item from the queue without removing it. The C<peek_front>
and C<peek_back> methods inspect the item at the front and the back of
the queue, respectively. The generic C<peek> method is equivalent to
C<peek_front> for FIFO style queues and C<peek_back> for LIFO style
queues. If an index is specified, returns the item at that position
in the queue (where position 0 is the head of the queue). Negative
indices are supported, so a call to  C<< $queue->peek(-2) >>,
for example, would return the second to last item in the queue.

If the queue is empty or if the specified index is larger than the
number of elements currently in the queue, these methods will 
return C<undef> without blocking.

Note that unlike the 
L<<"peek" method in C<Thread::Queue>|Thread::Queue/"peek">>,
C<Forks::Queue::peek> returns a copy of the item on the queue,
so manipulating a reference returned from C<peek> while B<not>
affect the item on the queue.

=head2 extract

=head2 $item = $queue->extract

=head2 $item = $queue->extract($index)

=head2 @items = $queue->extract($index,$count)

Removes and returns the specified number of items from the queue
at the specified index position, to provide random access to the
queue. The method is non-blocking and may return fewer than the
number of items requested (or zero items) if there are not enough
items in the queue to satisfy the request.

If the C<$count> argument is not provided, the method will return
(if available) a single item. If the C<$index> argument is also
not provided, it will return the first item on the queue exactly
like the L<"get_nb"> method with no arguments.

Negative C<$index> values are supported, in which case this
method will extract the corresponding items at the back of the
queue.

Like C<get()> vs. C<get($count)>, the return value is always a
scalar when no C<$count> argument is provided, and always a list
when it is.


=head2 insert

=head2 $count = $queue->insert($index, @list)

Provides random access to the queue, inserting the items specified
in C<@list> into the queue after index position C<$index>.
Negative C<$index> values are supported, which indicate that the
items should be inserted after that position relative to the
back of the queue.

Returns the number of items that were inserted into the queue.
If the queue has a L<"limit"> set, and inserting all the items on
the list would cause the queue size to exceed the limit, this
method will either block until capacity to insert the whole list
becomes available, or it will insert items up to the queue size
limit and issue a warning about the uninserted items, depending
on the queue's L<"on_limit"|Forks::Queue/"new"> setting.

This method is inefficient for some queue implementations.


=head2 pending

=head2 $num_items_avail = $queue->pending

Returns the total number of items available on the queue. There is no
guarentee that the number of available items will not change between a
call to C<pending> and a subsequent call to L<"get">

=head2 clear

=head2 $queue->clear

Removes all items from the queue.


=head2 status

=head2 $status = $queue->status

Returns a hash reference with meta information about the queue.
The information should at least include the number of items remaining in
the queue. Other implementations may provide additional information
in this return value.


=head2 limit

=head2 $max = $queue->limit

=head2 $queue->limit( $new_limit )

=head2 $queue->limit( $new_limit, $on_limit )

=head2 $queue->limit = $new_limit

Returns or updates the maximum size of the queue. With no args, returns
the existing maximum queue size, with a non-positive value indicating
that the queue does not have a maximum size. The return value also acts
as an lvalue through which the maximum queue size can be set, and
allows the C<limit> method to be used in the same way as 
L<Thread::Queue/"limit">.

If arguments are provided, the first argument is used to set the
maximum queue size. A non-positive queue size can be specified to
indicate that the queue does not have a maximum size. 
The second argument, if provided, updates the behavior of the queue
when an attempt is made to add items beyond the maximum size.
The acceptable values for the second argument are C<block>, which causes
an insertion operation to block until there is capacity on the queue,
or C<fail>, which returns immediately from an insertion operation with
a warning about items that were not added to the queue.


=head1 VARIABLES

=head2 %OPTS

Global hash containing the set of default options for all
C<Forks::Queue> constructors. Initially this hash contains the
key-value pairs

        impl            "File"
        style           "fifo"
        limit           -1
        on_limit        "fail"

but they may be changed at any time to affect all subsequently
constructed C<Forks::Queue> objects. The global options can also
be set at import time with additional arguments for the C<use>
statement.

    use Forks::Queue impl => 'SQLite';    # use SQLite queues by default
    $Forks::Queue::OPTS{impl} = 'SQLite'; # equivalent run-time call
    
    use Forks::Queue
        on_limit => 'block', limit => 10; # finite, blocking queues by default
    $Forks::Queue::OPTS{limit} = 10;
    $Forks::Queue::OPTS{on_limit} = 'block';  # equivalent run-time calls

=head1 ENVIRONMENT

Some environment variable settings that can affect this module:

=over 4

=item * FORKS_QUEUE_IMPL

Specifies a default implementation to use, overriding the initial setting
of C<$Forks::Queue::OPTS{"impl"}>, in cases where the C<Forks::Queue>
constructor is invoked without passing an C<impl> option.

=item * FORKS_QUEUE_DEBUG

If set to a true value, outputs information about the activity of
the queues to standard error.

=item * FORKS_QUEUE_NOTIFY

If set to a false value, disables use of signals on POSIX-y platforms
that may help improve queue performance

=item * FORKS_QUEUE_DIR

Specifies a directory to use for temporary queue files in the
L<File|Forks::Queue::File> and L<SQLite|Forks::Queue::SQLite> implementations.
If this directory is not specified, the implementations will try to make
a reasonable choice based on your platform and other environment settings.

=back

=head1 DEPENDENCIES

The C<Forks::Queue> module and all its current implementations require
the L<JSON|JSON> module.

=head1 SEE ALSO

L<Thread::Queue|Thread::Queue>, L<File::Queue|File::Queue>,
L<Queue::Q|Queue::Q>, L<MCE::Queue|MCE::Queue>,
L<Queue::DBI|Queue::DBI>, L<Directory::Queue|Directory::Queue>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Forks::Queue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Forks-Queue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Forks-Queue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Forks-Queue>

=item * Search CPAN

L<http://search.cpan.org/dist/Forks-Queue/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

# TODO:
#
#     priorities
#     Directory implementation (see Queue::Dir)
# _X_ Better thread support
#     network implementation with simple client-server
#     even better thread support, 2nd signal from main to threads    
#     import function to set global impl, limit, on_limit settings
