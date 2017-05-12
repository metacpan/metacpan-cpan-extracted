package Future::Q;
use strict;
use warnings;
use Future 0.29;
use parent "Future";
use Devel::GlobalDestruction;
use Scalar::Util qw(refaddr blessed weaken);
use Carp;
use Try::Tiny ();

our $VERSION = '0.110';

our @CARP_NOT = qw(Try::Tiny Future);

our $OnError = undef;

## ** lexical attributes to avoid collision of names.

my %failure_handled_for = ();

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    my $id = refaddr $self;
    $failure_handled_for{$id} = 0;
    return $self;
}

sub _q_go_super_DESTROY {
    my ($self) = @_;
    my $super_destroy = $self->can("SUPER::DESTROY");
    goto $super_destroy if defined $super_destroy;
}

sub DESTROY {
    my ($self) = @_;
    if(in_global_destruction) {
        goto \&_q_go_super_DESTROY;
    }
    my $id = refaddr $self;
    if($self->is_ready && $self->failure && !$failure_handled_for{$id}) {
        $self->_q_warn_failure();
        my @failed_subfutures = Try::Tiny::try {
            $self->failed_futures;
        }Try::Tiny::catch {
            ();
        };
        foreach my $f (@failed_subfutures) {
            $f->_q_warn_failure(is_subfuture => 1) if blessed($f) && $f->can('_q_warn_failure');
        }
    }
    delete $failure_handled_for{$id};
    goto \&_q_go_super_DESTROY;
}

sub _q_set_failure_handled {
    my ($self) = @_;
    $failure_handled_for{refaddr $self} = 1;
}

sub _q_warn_failure {
    my ($self, %options) = @_;
    if($self->is_ready && $self->failure) {
        my $failure = $self->failure;
        my $message = Carp::shortmess($options{is_subfuture}
                                      ? "Failure of subfuture $self may not be handled: $failure  subfuture may be lost"
                                      : "Failure of $self is not handled: $failure  future is lost");
        if(defined($OnError) && ref($OnError) eq "CODE") {
            $OnError->($message);
        }else {
            warn $message;
        }
    }
}

sub try {
    my ($class, $func, @args) = @_;
    if(!defined($func) || ref($func) ne "CODE") {
        $func = sub {
            croak("func parameter for try() must be a code-ref");
        };
    }
    my $result_future = Try::Tiny::try {
        my @results = $func->(@args);
        if(scalar(@results) == 1 && blessed($results[0]) && $results[0]->isa('Future')) {
            return $results[0];
        }else {
            return $class->new->fulfill(@results);
        }
    } Try::Tiny::catch {
        my $e = shift;
        return $class->new->reject($e);
    };
    return $result_future;
}

sub fcall {
    goto $_[0]->can('try');
}

sub then {
    my ($self, $on_fulfilled, $on_rejected) = @_;
    if(defined($on_fulfilled) && ref($on_fulfilled) ne "CODE") {
        $on_fulfilled = undef;
    }
    if(defined($on_rejected) && ref($on_rejected) ne "CODE") {
        $on_rejected = undef;
    }
    my $class = ref($self);
    $self->_q_set_failure_handled();
    
    my $next_future = $self->new;
    $self->on_ready(sub {
        my $invo_future = shift;
        if($invo_future->is_cancelled) {
            $next_future->cancel() if $next_future->is_pending;
            return;
        }
        my $return_future = $invo_future;
        if($invo_future->is_rejected && defined($on_rejected)) {
            $return_future = $class->try($on_rejected, $invo_future->failure);
        }elsif($invo_future->is_fulfilled && defined($on_fulfilled)) {
            $return_future = $class->try($on_fulfilled, $invo_future->get);
        }
        $next_future->resolve($return_future);
    });
    if($next_future->is_pending && $self->is_pending) {
        weaken(my $invo_future = $self);
        $next_future->on_cancel(sub {
            if(defined($invo_future) && $invo_future->is_pending) {
                $invo_future->cancel();
            }
        });
    }
    return $next_future;
}

sub catch {
    my ($self, $on_rejected) = @_;
    @_ = ($self, undef, $on_rejected);
    goto $self->can('then');
}

sub fulfill {
    goto $_[0]->can('done');
}

sub resolve {
    my ($self, @result) = @_;
    if(not (@result == 1 && blessed($result[0]) && $result[0]->isa("Future"))) {
        goto $self->can("fulfill");
    }
    return $self if $self->is_cancelled;
    my $base_future = $result[0];

    ## Maybe we should check if $base_future is identical to
    ## $self. Promises/A+ spec v1.1 [1] states we should reject $self
    ## in that case. However, since Q v1.0.1 does not care that case,
    ## we also leave that case unchecked for now.
    ##
    ## [1]: https://github.com/promises-aplus/promises-spec/tree/1.1.0
    
    $base_future->on_ready(sub {
        my $base_future = shift;
        return if $self->is_ready;
        if($base_future->is_cancelled) {
            $self->cancel();
        }elsif($base_future->failure) {
            if($base_future->can("_q_set_failure_handled")) {
                $base_future->_q_set_failure_handled();
            }
            $self->reject($base_future->failure);
        }else {
            $self->fulfill($base_future->get);
        }
    });
    if(!$base_future->is_ready) {
        weaken(my $weak_base = $base_future);
        $self->on_cancel(sub {
            $weak_base->cancel() if defined($weak_base) && !$weak_base->is_ready;
        });
    }
    return $self;
}

sub reject {
    goto $_[0]->can('fail');
}

sub is_pending {
    my ($self) = @_;
    return !$self->is_ready;
}

sub is_fulfilled {
    my ($self) = @_;
    return (!$self->is_pending && !$self->is_cancelled && !$self->is_rejected);
}

sub is_rejected {
    my ($self) = @_;
    return ($self->is_ready && !!$self->failure);
}

foreach my $method (qw(wait_all wait_any needs_all needs_any)) {
    no strict "refs";
    my $supermethod_code = __PACKAGE__->can("SUPER::$method");
    *{$method} = sub {
        my ($self, @subfutures) = @_;
        foreach my $sub (@subfutures) {
            next if !blessed($sub) || !$sub->can('_q_set_failure_handled');
            $sub->_q_set_failure_handled();
        }
        goto $supermethod_code;
    };
}

sub finally {
    my ($self, $callback) = @_;
    my $class = ref($self);
    $self->_q_set_failure_handled();
    if(!defined($callback) || ref($callback) ne "CODE") {
        return $class->new->reject("Callback for finally() must be a code-ref");
    }
    my $next_future = $self->new;
    $self->on_ready(sub {
        my ($invo_future) = @_;
        if($invo_future->is_cancelled) {
            $next_future->cancel if $next_future->is_pending;
            return;
        }
        my $returned_future = $class->try($callback);
        $returned_future->on_ready(sub {
            my ($returned_future) = @_;
            if(!$returned_future->is_cancelled && $returned_future->failure) {
                $next_future->resolve($returned_future);
            }else {
                $next_future->resolve($invo_future);
            }
        });
        if(!$returned_future->is_ready) {
            weaken(my $weak_returned = $returned_future);
            $next_future->on_cancel(sub {
                $weak_returned->cancel if defined($weak_returned) && !$weak_returned->is_ready;
            });
        }
    });
    if(!$self->is_ready) {
        weaken(my $weak_invo = $self);
        $next_future->on_cancel(sub {
            $weak_invo->cancel if defined($weak_invo) && !$weak_invo->is_ready;
        
        });
    }
    return $next_future;
}

1;

__END__

=head1 NAME

Future::Q - a Future (or Promise or Deferred) like Q module for JavaScript

=head1 SYNOPSIS

    use Future::Q;

    sub async_func_future {
        my @args = @_;
        my $f = Future::Q->new;
        other_async_func(   ## This is a regular callback-style async function
            args => \@args,
            on_success => sub { $f->fulfill(@_) },
            on_failure => sub { $f->reject(@_) },
        );
        return $f;
    }

    async_func_future()->then(sub {
        my @results = @_;
        my @processed_values = do_some_processing(@results);
        return @processed_values;
    })->then(sub {
        my @values = @_;   ## same values as @processed_values
        return async_func_future(@values);
    })->then(sub {
        warn "Operation finished.\n";
    })->catch(sub {
        ## failure handler
        my $error = shift;
        warn "Error: $error\n";
    });

=head1 DESCRIPTION

L<Future::Q> is a subclass of L<Future>.
It extends its API with C<then()> and C<try()> etc, which are
almost completely compatible with Kris Kowal's Q module for JavaScript.

L<Future::Q>'s API and documentation is designed to be self-contained,
at least for basic usage of Futures.
If a certain function you want is missing in this module,
you should refer to L</Missing Methods and Features> section and/or L<Future>.
(But be prepared because L<Future> has a lot of methods!)

Basically a Future (in a broad meaning) represents an operation (whether it's in progress
or finished) and its results.
It is also referred to as "Promise" or "Deferred" in other contexts.
For further information as to what Future is all about, see:

=over

=item *

L<Future> - the base class

=item *

L<Promises> - another Future/Promise/Deferred implementation with pretty good documentation

=item *

L<Q|http://documentup.com/kriskowal/q/> - JavaScript module

=back

=head2 Terminology of Future States

Any L<Future::Q> object is in one of the following four states.

=over

=item 1.

B<pending> - The operation represented by the L<Future::Q> object is now in progress.

=item 2.

B<fulfilled> - The operation has succeeded and the L<Future::Q> object has its results.
The results can be obtained by C<get()> method.

=item 3.

B<rejected> - The operation has failed and the L<Future::Q> object has the reason of the failure.
The reason of the failure can be obtained by C<failure()> method.

=item 4.

B<cancelled> - The operation has been cancelled.

=back

The state transition is one-way; "pending" -> "fulfilled", "pending" -> "rejected" or "pending" -> "cancelled".
Once the state moves to a non-pending state, its state never changes anymore.

In the terminology of L<Future>, "done" and "failed" are used for "fulfilled" and "rejected", respectively.

You can check the state of a L<Future::Q> with predicate methods C<is_pending()>, C<is_fulfilled()>, C<is_rejected()> and C<is_cancelled()>.

=head2 then() Method

Using C<then()> method, you can register callback functions with a L<Future::Q> object.
The callback functions are executed when the L<Future::Q> object is fulfilled or rejected.
You can obtain and use the results of the L<Future::Q> within the callbacks.

The return value of C<then()> method represents the results of the callback function (if it's executed).
Since the callback function is also an operation in progress, the return value of C<then()> is naturally a L<Future::Q> object.
By calling C<then()> method on the returned L<Future::Q> object, you can chain a series of operations
that are executed sequentially.

See the specification of C<then()> method below for details.

=head2 Reporting Unhandled Failures

L<Future::Q> warns you when a rejected L<Future::Q> object is destroyed without its failure handled.
This is because ignoring a rejected L<Future::Q> is just as dangerous as ignoring a thrown exception.
Any rejected L<Future::Q> object must be handled properly.

By default
when a rejected but unhandled L<Future::Q> is destroyed,
the reason of the failure is printed through Perl's warning facility.
This behavior can be modified by setting C<$OnError> package variable (see below).

L<Future::Q> thinks failures of the following futures are "handled".

=over

=item *

Futures that C<then()>, C<catch()> or C<finally()> method has been called on.

=item *

Futures returned by C<$on_fulfilled> or C<$on_rejected> callbacks for C<then()> or C<catch()> method.

=item *

Futures returned by C<$callback> for C<finally()> method.

=item *

Subfutures given to C<wait_all()>, C<wait_any()>, C<needs_all()> and C<needs_any()> method.

=item *

Futures given to another Future's C<resolve()> method as its single argument.

=back

So make sure to call C<catch()> method at the end of any callback chain to handle failures.

I also recommend always inspecting failed subfutures using C<failed_futures()> method
in callbacks for dependent futures returned by C<wait_all()>, C<wait_any()>, C<needs_all()> and C<needs_any()>.
This is because there may be multiple of failed subfutures.
It is even possible that some subfutures fail but the dependent future succeeds.

=head1 PACKAGE VARIABLES

You can set the following package variables to change L<Future::Q>'s behavior.

=head2 $OnError

A subroutine reference called when a rejected but unhandled L<Future::Q> object is destroyed.

C<$OnError> is called like

    $OnError->($warning_message)

The C<$warning_message> can be evaluated to a human-readable string
(It IS a string actually, but this may change in future versions).
So you can pass the string to a logger, for example.

    my $logger = ...;
    
    $Future::Q::OnError = sub {
        my ($warning_message) = @_;
        $logger->warn("Unhanlded Future: " . $warning_message);
    };

If C<$OnError> is C<undef>, which is the default,
C<$warning_message> is printed by the built-in C<warn()> function.
You can capture it by setting C<$SIG{__WARN__}>.



=head1 CLASS METHODS

In addition to all class methods in L<Future>,
L<Future::Q> has the following class methods.

=head2 $future = Future::Q->new()

Constructor. It creates a new pending L<Future::Q> object.

=head2 $future = Future::Q->try($func, @args)

=head2 $future = Future::Q->fcall($func, @args)

Immediately executes the C<$func> with the arguments C<@args>, and returns
a L<Future> object that represents the result of C<$func>.

C<fcall()> method is an alias of C<try()> method.

C<$func> is a subroutine reference. It is executed with the optional arguments C<@args>.

The return value (C<$future>) is determined by the following rules:

=over

=item *

If C<$func> returns a single L<Future> object, C<$future> is that object.

=item *

If C<$func> throws an exception, C<$future> is a rejected L<Future::Q> object with that exception.
The exception is never rethrown to the upper stacks.

=item *

Otherwise, C<$future> is a fulfilled L<Future::Q> object with the values returned by C<$func>.

=back

If C<$func> is not a subroutine reference, it returns a rejected L<Future::Q> object.

=head1 OBJECT METHODS

In addition to all object methods in L<Future>, L<Future::Q> has the following object methods.

=head2 $next_future = $future->then([$on_fulfilled, $on_rejected])

Registers callback functions that are executed when C<$future> is fulfilled or rejected,
and returns a new L<Future::Q> object that represents the result of the whole operation.

B<< Difference from then() method of L<Future> >>

L<Future::Q> overrides the C<then()> method of the base L<Future> class.
Basically they behave in the same way, but in C<then()> method of L<Future::Q>,

=over

=item *

the callback funcions do not have to return a L<Future> object.
If they do not, the return values are automatically transformed into a fulfilled L<Future::Q> object.

=item *

it will not warn you even if you call the C<then()> method in void context.

=back

B<< Detailed specification >>

Below is the detailed specification of C<then()> method.

C<$on_fulfilled> and C<$on_rejected> are subroutine references.
When C<$future> is fulfilled, C<$on_fulfilled> callback is executed.
Its arguments are the values of the C<$future>, which are obtained by C<< $future->get >> method.
When C<$future> is rejected, C<$on_rejected> callback is executed.
Its arguments are the reason of the failure, which are obtained by C<< $future->failure >> method.
Both C<$on_fulfilled> and C<$on_rejected> are optional.

C<$next_future> is a new L<Future::Q> object.
In a nutshell, it represents the result of C<$future> and the subsequent execution of C<$on_fulfilled>
or C<$on_rejected> callback.

In detail, the state of C<$next_future> is determined by the following rules.

=over

=item *

While C<$future> is pending, C<$next_future> is pending.

=item *

When C<$future> is cancelled, neither C<$on_fulfilled> or C<$on_rejected> is executed,
and C<$next_future> becomes cancelled.

=item *

When C<$future> is fulfilled and C<$on_fulfilled> is C<undef>,
C<$next_future> is fulfilled with the same values as C<$future>.

=item *

When C<$future> is rejected and C<$on_rejected> is C<undef>,
C<$next_future> is rejected with the same values as C<$future>.

=item *

When C<$future> is fulfilled and C<$on_fulfilled> is provided,
C<$on_fulfilled> is executed.
In this case C<$next_future> represents the result of C<$on_fulfilled> callback (see below).

    @returned_values = $on_fulfilled->(@values)

=item *

When C<$future> is rejected and C<$on_rejected> is provided,
C<$on_rejected> is executed.
In this case C<$next_future> represents the result of C<$on_rejected> callback (see below).

    @returned_values = $on_rejected->($exception, @detail)

=item *

In the above two cases where C<$on_fulfilled> or C<$on_rejected> callback is executed,
the following rules are applied to C<$next_future>.

=over

=item *

If the callback returns a single L<Future> (call it C<$returned_future>),
C<$next_future>'s state is synchronized with that of C<$returned_future>.

=item *

If the callback throws an exception,
C<$next_future> is rejected with that exception.
The exception is never rethrown to the upper stacks.

=item *

Otherwise, C<$next_future> is fulfilled with the values returned by the callback.

=back

=back

Note that the whole operation can be executed immediately.
For example, if C<$future> is already fulfilled,
C<$on_fulfilled> callback is executed before C<$next_future> is returned.
And if C<$on_fulfilled> callback does not return a pending L<Future>,
C<$next_future> is already in a non-pending state.

You can call C<cancel()> method on C<$next_future>.
If C<$future> is pending, it is cancelled when C<$next_future> is cancelled.
If either C<$on_fulfilled> or C<$on_rejected> is executed and its C<$returned_future>
is pending, the C<$returned_future> is cancelled when C<$next_future> is cancelled.

You should not call C<fulfill()>, C<reject()>, C<resolve()> etc on C<$next_future>.

Because C<then()> method passes the C<$future>'s failure to C<$on_rejected> callback or C<$next_future>,
C<$future>'s failure becomes "handled", i.e., L<Future::Q> won't warn you
if C<$future> is rejected and DESTROYed.


=head2 $next_future = $future->catch([$on_rejected])

Alias of C<< $future->then(undef, $on_rejected) >>.

B<Note:> The superclass L<Future> has its own C<catch> method since version 0.33.
L<Future>'s C<catch> method is different from L<Future::Q>'s, and L<Future::Q> overrides it.

=head2 $next_future = $future->finally($callback)

Registers a callback function that is executed when C<$future> is either fulfilled or rejected.
This callback is analogous to "finally" block of try-catch-finally statements found in Java etc.

It returns a new L<Future::Q> object (C<$next_future>) that keeps the result of the operation.

The mandatory argument, C<$callback>, is a subroutine reference.
It is executed with no arguments when C<$future> is either fulfilled or rejected.

    @returned_values = $callback->()

If C<$callback> finishes successfully, C<$next_future> has the same state and values as C<$future>.
That is, if C<$future> is fulfilled C<$next_future> becomes fulfilled with the same values,
and if C<$future> is rejected C<$next_future> becomes rejected with the same failure.
In this case the return values of C<$callback> are discarded.

If C<$callback> fails, C<$next_future> is rejected with the failure thrown by C<$callback>.
In this case the values of C<$future> are discarded.

In detail, the state of C<$next_future> is determined by the following rules.

=over

=item *

When C<$future> is pending, C<$next_future> is pending.

=item *

When C<$future> is cancelled, C<$callback> is not executed, and C<$next_future> becomes cancelled.

=item *

When C<$future> is fulfilled or rejected, C<$callback> is executed with no arguments.
C<$next_future>'s state depends on the result of C<$callback>.

=item *

If the C<$callback> returns a single L<Future> (call it C<$returned_future>),
C<$next_future> waits for C<$returned_future> to become non-pending state.

=over

=item *

When C<$returned_future> is pending, C<$next_future> is pending.

=item *

When C<$returned_future> is fulfilled or cancelled, C<$next_future> has the same state and values as B<< C<$future> >>.
In this case, values of C<$returned_future> are discarded.

=item *

When C<$returned_future> is rejected, C<$next_future> is rejected with C<$returned_future>'s failure.

=back

=item *

If the C<$callback> throws an exception, C<$next_future> is rejected with that exception.
The exception is never rethrown to the upper stacks.

=item *

Otherwise, C<$next_future> has the same state and values as B<< C<$future> >>.
Values returned from C<$callback> are discarded.

=back

You can call C<cancel()> method on C<$next_future>.
If C<$future> is pending, it is cancelled when C<$next_future> is cancelled.
If C<$callback> returns a single L<Future> and the C<$returned_future> is pending,
the C<$returned_future> is cancelled when C<$next_future> is cancelled.

You should not call C<fulfill()>, C<reject()>, C<resolve()> etc on C<$next_future>.

Because C<finally()> method passes the C<$future>'s failure to C<$next_future>,
C<$future>'s failure becomes "handled", i.e., L<Future::Q> won't warn you
if C<$future> is rejected and DESTROYed.


=head2 $future = $future->fulfill(@result)

Fulfills the pending C<$future> with the values C<@result>.

This method is an alias of C<< $future->done(@result) >>.

=head2 $future = $future->reject($exception, @details)

Rejects the pending C<$future> with the C<$exception> and optional C<@details>.
C<$exception> must be a scalar evaluated as boolean true.

This method is an alias of C<fail()> method (not C<die()> method).

=head2 $future = $future->resolve(@result)

Basically same as C<fulfill()> method, but if you call it with a single L<Future> object as the argument,
C<$future> will follow the given L<Future>'s state.

Suppose you call C<< $future->resolve($base_future) >>, then

=over

=item *

If C<$base_future> is pending, C<$future> is pending. When C<$base_future> changes its state,
C<$future> will change its state to C<$base_future>'s state with the same values.

=item *

If C<$base_future> is fulfilled, C<$future> is immediately fulfilled with the same values as C<$base_future>'s.

=item *

If C<$base_future> is rejected, C<$future> is immediately rejected with the same values as C<$base_future>'s.

=item *

If C<$base_future> is cancelled, C<$future> is immediately cancelled.

=back

After calling C<resolve()>, you should not call C<fulfill()>, C<reject()>, C<resolve()> etc on the C<$future> anymore.

You can call C<cancel()> on C<$future> afterward. If you call C<< $future->cancel() >>, C<$base_future> is cancelled, too.

Because C<$base_future>'s state is passed to C<$future>, C<$base_future>'s failure becomes "handled", i.e.,
L<Future::Q> won't warn you when C<$base_future> is rejected and DESTROYed.


=head2 $is_pending = $future->is_pending()

Returns true if the C<$future> is pending. It returns false otherwise.

=head2 $is_fulfilled = $future->is_fulfilled()

Returns true if the C<$future> is fulfilled. It returns false otherwise.

=head2 $is_rejected = $future->is_rejected()

Returns true if the C<$future> is rejected. It returns false otherwise.

=head2 $is_cancelled = $future->is_cancelled()

Returns true if the C<$future> is cancelled. It returns false otherwise.
This method is inherited from L<Future>.

=head1 EXAMPLE

=head2 try() and then()

    use Future::Q;

    ## Values returned from try() callback are transformed into a
    ## fulfilled Future::Q
    Future::Q->try(sub {
        return (1,2,3);
    })->then(sub {
        print join(",", @_), "\n"; ## -> 1,2,3
    });

    ## Exception thrown from try() callback is transformed into a
    ## rejected Future::Q
    Future::Q->try(sub {
        die "oops!";
    })->catch(sub {
        my $e = shift;
        print $e;       ## -> oops! at eg/try.pl line XX.
    });

    ## A Future returned from try() callback is returned as is.
    my $f = Future::Q->new;
    Future::Q->try(sub {
        return $f;
    })->then(sub {
        print "This is not executed.";
    }, sub {
        print join(",", @_), "\n";  ## -> a,b,c
    });
    $f->reject("a", "b", "c");

=head2 finally()

    use Future::Q;
    
    my $handle;
    
    ## Suppose Some::Resource->open() returns a handle to a resource (like
    ## database) wrapped in a Future
    
    Some::Resource->open()->then(sub {
        $handle = shift;
        return $handle->read_data(); ## Read data asynchronously
    })->then(sub {
        my $data = shift;
        print "Got data: $data\n";
    })->finally(sub {
        ## Ensure closing the resource handle. This callback is called
        ## even when open() or read_data() fails.
        $handle->close() if $handle; 
    });

=head1 DIFFERENCE FROM Q

Although L<Future::Q> tries to emulate the behavior of Q module for JavaScript as much as possible,
there is difference in some respects.

=over

=item *

L<Future::Q> has both roles of "promise" and "deferred" in Q.
Currently there is no read-only future like "promise".

=item *

L<Future::Q> has the fourth state "cancelled", while promise in Q does not.

=item *

In L<Future::Q>, callbacks for C<then()> and C<try()> methods can be executed immediately,
while they are always deferred in Q.
This is because L<Future::Q> does not assume any event loop mechanism.

=item *

In L<Future::Q>, you must pass a truthy value to C<reject()> method.
This is required by the original L<Future> class.

=back



=head2 Missing Methods and Features

Some methods and features in Q module are missing in L<Future::Q>.
Some of them worth noting are listed below.

=over

=item promise.fail()

L<Future> already has C<fail()> method for a completely different meaning.
Use C<catch()> method instead.

=item promise.progress(), deferred.notify()

Progress handlers are not supported in this version of L<Future::Q>.

=item promise.done()

L<Future> already has C<done()> method for a completely different meaning.
L<Future::Q> doesn't need the equivalent of Q's C<done()> method because rejected and unhandled futures are detected
in their C<DESTROY()> method. See also L</Reporting Unhandled Failures>.

=item promise.fcall() (object method)

Its class method form is enough to get the job done.
Use C<< Future::Q->fcall() >>.

=item promise.all(), promise.allResolve(), promise.allSettled()

Use C<< Future::Q->needs_all() >> and C<< Future::Q->wait_all() >> methods inherited from the original L<Future> class.

=item promise.inspect()

Use predicate methods C<is_pending()>, C<is_fulfilled()>, C<is_rejected()> and C<is_cancelled()>.
To obtain values from a fulfilled L<Future>, use C<get()> method.
To obtain the reason of the failure from a rejected L<Future>, use C<failure()> method.

=item Q()

Use C<< Future::Q->wrap() >> method inherited from the original L<Future> class.

=item Q.onerror

Use C<$OnError> package variable, although it is not exactly the same as C<Q.onerror>. See also L</Reporting Unhandled Failures>.

=back


=head1 SEE ALSO

=over

=item L<Q|http://documentup.com/kriskowal/q/>

The JavaScript module that L<Future::Q> tries to emulate.

=item L<Promises/A+|http://promises-aplus.github.io/promises-spec/>

"Promises/A+" specification for JavaScript promises. This is the spec that Q implements.

=item L<Future>

Base class of this module. L<Future> has a lot of methods you may find
interesting.

=item L<Future::Utils>

Utility functions for L<Future>s.  Note that the error handling
mechanism of L<Future::Q> may not work well with L<Future::Utils>
functions.
Personally I recommend using L<CPS> for looping asynchronous operations.


=item L<IO::Async::Future>

Subclass of L<Future> that works well with L<IO::Async> event framework.

=item L<Promises>

Another promise/deferred/future/whatever implementation.
Its goal is to implement Promises/A+ specification.
Because Q is also an implementation of Promises/A+, L<Promises> and Q (and L<Future::Q>) are very similar.


=item L<AnyEvent::Promises>

Another port of Q (implementation of Promises/A+) in Perl.
It depends on L<AnyEvent>.

=item L<AnyEvent::Promise>

A simple Promise used with L<AnyEvent> condition variables. Apparently it has nothing to do with Promises/A+.


     [AnyEvent::Promise]
                [Future] -\
                           +-- [Future::Q]
    [Promises/A+] -- [Q] -/
                  -- [Promises]
                  -- [AnyEvent::Promises]

=back

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Future-Q/issues>

=head1 ACKNOWLEDGEMENT

Paul Evans, C<< <leonerd at leonerd.org.uk> >> - author of L<Future>


=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

