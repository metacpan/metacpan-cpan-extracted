package JSPL::Context::Timeout;
use strict;
use warnings;
use Time::HiRes qw(alarm time);
use POSIX qw(SIGALRM);
use JSPL ();
use Carp;

our $VERSION = '0.20';
our %TO = ();

BEGIN {
    *_orig_eval = \&JSPL::Context::eval;
    *_orig_call = \&JSPL::Context::call;
}

sub _handler {
    my $id = $JSPL::Context::CURRENT;
    die "Operation timeout\n" unless $TO{$id}{cb};
    my $res = $TO{$id}{cb}->();
    no warnings 'numeric';
    alarm($res) if($res && ($res *= 1.0) > 0.0);
    alarm($TO{$id}{to}) if $res && $res == -1;
    $res;
}

sub _eval_wto_alarm_opcb {
    my $id = $_[0]->id;
    if($TO{$id}) {
	my $self = shift;
	$self->jsc_set_opcb(\&_handler);
	my $old = POSIX::SigAction->new;
	POSIX::sigaction(
	    SIGALRM,
	    POSIX::SigAction->new(sub { $self->jsc_trigger_opcb }), $old);
	local $TO{$id}{it} = time;
	alarm($TO{$id}{to});
	my $res = eval { _orig_eval($self, @_) };
	alarm(0);
	POSIX::sigaction(SIGALRM, $old);
	$self->jsc_set_opcb(undef);
	die $@ if($@ && $self->{RaiseExceptions});
	return $res;
    } else {
	goto &_orig_eval; 
    }
}

sub _call_wto_alarm_opcb {
    my $id = $_[0]->id;
    if($TO{$id}) {
	my $self = shift;
	$self->jsc_set_opcb(\&_handler);
	my $old = POSIX::SigAction->new;
	POSIX::sigaction(
	    SIGALRM,
	    POSIX::SigAction->new(sub { $self->jsc_trigger_opcb }),
	    $old
	);
	local $TO{$id}{it} = time;
	alarm($TO{$id}{to});
	my $res = eval { _orig_call($self, @_) };
	alarm(0);
	POSIX::sigaction(SIGALRM, $old);
	$self->jsc_set_opcb(undef);
	die $@ if($@ && $self->{RaiseExceptions});
	return $res;
    } else {
	goto &_orig_call;
    }
}

sub _handler_bh {
    JSPL::Context->current->_trigger_tocb(undef);
    &_handler;
}

sub _eval_wto_alarm_bh {
    my $id = $_[0]->id;
    if($TO{$id}) {
	my $self = shift;
	my $old = POSIX::SigAction->new;
	$self->_set_tocb(1);
	POSIX::sigaction(
	    SIGALRM,
	    POSIX::SigAction->new(sub { $self->_trigger_tocb(\&_handler_bh) }),
	    $old
	);
	local $TO{$id}{it} = time;
	alarm($TO{$id}{to});
	my $res = eval { _orig_eval($self, @_) };
	alarm(0);
	POSIX::sigaction(SIGALRM, $old);
	$self->_set_tocb(undef);
	die $@ if($@ && $self->{RaiseExceptions});
	return $res;
    } else {
	goto &_orig_eval;
    }
}

sub _call_wto_alarm_bh {
    my $id = $_[0]->id;
    if($TO{$id}) {
	my $self = shift;
	my $old = POSIX::SigAction->new;
	$self->_set_tocb(1);
	POSIX::sigaction(
	    SIGALRM,
	    POSIX::SigAction->new(sub { $self->_trigger_tocb(\&_handler_bh) }),
	    $old
	);
	local $TO{$id}{it} = time;
	alarm($TO{$id}{to});
	my $res = eval { _orig_eval($self, @_) };
	alarm(0);
	POSIX::sigaction(SIGALRM, $old);
	$self->_set_tocb(undef);
	die $@ if($@ && $self->{RaiseExceptions});
	return $res;
    } else {
	goto &_orig_eval;
    }
}

our %Implementations = (
    'alarm' => {
	'eval' => \&_eval_wto_alarm_opcb,
	'call' => \&_call_wto_alarm_opcb,
    },
    'alarm_bh' => {
	'eval' => \&_eval_wto_alarm_bh,
	'call' => \&_call_wto_alarm_bh,
    },
);

sub import {
    shift; # I'm a method
    my($impl, $sufix) = ('alarm', '_wto');
    my $arg = shift || '';
    if($arg eq ':global') {
	$sufix = ''; 
	$arg = shift || '';
    }
    $impl = $arg if $arg;
    $impl .= '_bh' unless JSPL::does_support_opcb;

    my $Impl = $Implementations{$impl} 
	or croak "JSPL::Context::Timeout: implementation '$impl' not available\n";

    no strict 'refs';
    *{"JSPL::Context::eval$sufix"} = $Impl->{'eval'};
    *{"JSPL::Context::call$sufix"} = $Impl->{'call'};
}

JSPL::_boot_(__PACKAGE__, $JSPL::VERSION);

package JSPL::Context;

sub set_timeout {
    my($self, $timeout, $cb) = @_;
    $TO{$self->id} = {to => $timeout, cb => $cb};
}

sub clear_timeout {
    my $self = shift;
    delete $TO{$self->id};
}

1;

__END__

=head1 NAME

JSPL::Context::Timeout - Call JavaScript with Timeouts

=head1 SYNOPSYS

    use JSPL;
    use JSPL::Context::Timeout;

    ...
    $ctx->set_timeout(1);
    # The folloing will throw a 'timeout' exception
    $ctx->eval_wto(q|
	var foo;
	while(1) {
	    foo++ 
	} 
    |);

=head1 DESCRIPTION

Up to SpiderMonkey v1.8.0 the documented way to control a runaway script was
using a I<branch handler> callback. JavaScript 1.8.1 (Gecko 1.9.1) introduced a
new I<OperationCallback> API and deprecated the I<branch handler> API.

This module uses the new API to extend L<JSPL::Context>. It adds hi-level
methods to control how long a JavaScript operation can run.

=head1 INSTANCE METHODS

A "use JSPL::Context::Timeout" adds to class L<JSPL::Context> the following:

=over 4

=item set_timeout($seconds, [ $callback ])

Set a timeout of I<$seconds> in the context for timeout-aware operations.
I<$seconds> can be fractional.

I<$callback> is an optional coderef which will get called if the timeout stops
the execution of an script. If I<$callback> is not given JSPL will cancel the
execution and will throw an C<Operation timeout> exception.

See the L</CALLBACKS> section below for a detailed discussion on the callback
semantics.

=item clear_timeout

Removes the operational timeout.

=item eval_wto($source )

Like L<JSPL::Context/eval> but be aware of the setted timeout if any.

=item call_wto($name, @arguments)

Like L<JSPL::Context/call> but be aware of the setted timeout if any.

=back

=head1 CALLBACKS

If you do not set a callback JSPL will always cancel the execution of the script
throwing an exception. Setting a callback allows you to have more control on
the response to a timeout. The value returned by the callback will be checked
and JSPL will act on it on the following way:

If you return a FALSE value, the script execution will be canceled. JSPL will
not throw the C<Operation timeout> exception in this case.

If you return a TRUE value from the callback the execution of the script will
be resumed. The return value taken as a number will be used to reset the
timeout timer as follows:

=over 4 

=item Any positive value

The timeout timer will be set to that value.

=item -1

The timer will be set to the original value passed to the C<set_timeout> call.

=item Any other value

The execution will be resumed but the timer won't be set. Effectively allowing the
script to continue forever until completion.

=back

In your callback you can freely re-enter JavaScript. The way you re-enter determines
if a new timeout is activated or not.

Any non-trapped exceptions in the callback cancel the execution of the original script.

=head1 BUGS AND CAVEATS

The current implementation is based on C<alarm> and POSIX signaling. This module do not
work in Win32 (yet).

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item jsc_set_opcb ( JSPL::Context, SV *handler )

Attaches an operation callback to the context

=item jsc_trigger_opcb ( JSPL::Context )

Triggers the operation callback on the context

=back

=cut
