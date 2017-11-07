package Future::Mojo;

use strict;
use warnings;
use Carp 'croak';
use Scalar::Util 'blessed', 'weaken';
use Mojo::IOLoop;

use parent 'Future';

our $VERSION = '0.004';

sub new {
	my $proto = shift;
	my $self = $proto->SUPER::new;
	
	$self->{loop} = ref $proto ? $proto->{loop} : (shift() // Mojo::IOLoop->singleton);
	
	return $self;
}

sub new_timer {
	my $proto = shift;
	my $self = (blessed $_[0] and $_[0]->isa('Mojo::IOLoop'))
		? $proto->new(shift) : $proto->new;
	
	$self->_set_timer(1, @_);
	
	return $self;
}

sub new_timeout {
	my $proto = shift;
	my $self = (blessed $_[0] and $_[0]->isa('Mojo::IOLoop'))
		? $proto->new(shift) : $proto->new;
	
	$self->_set_timer(0, @_);
	
	return $self;
}

sub _set_timer {
	my ($self, $succeed, $after) = @_;
	
	weaken(my $weakself = $self);
	my $cb = $succeed ? sub { $weakself->done if $weakself }
		: sub { $weakself->fail('Timeout') if $weakself };
	my $id = $self->loop->timer($after => $cb);
	
	$self->on_cancel(sub { shift->loop->remove($id) });
	
	return $self;
}

sub loop { shift->{loop} }

sub await {
	my $self = shift;
	croak 'Awaiting a future while the event loop is running would recurse'
		if $self->{loop}->is_running;
	$self->{loop}->one_tick until $self->is_ready;
}

sub done_next_tick {
	weaken(my $self = shift);
	my @result = @_;
	
	$self->loop->next_tick(sub { $self->done(@result) if $self });
	
	return $self;
}

sub fail_next_tick {
	weaken(my $self = shift);
	my ($exception, @details) = @_;
	
	croak 'Expected a true exception' unless $exception;
	
	$self->loop->next_tick(sub { $self->fail($exception, @details) if $self });
	
	return $self;
}

1;

=head1 NAME

Future::Mojo - use Future with Mojo::IOLoop

=head1 SYNOPSIS

 use Future::Mojo;
 use Mojo::IOLoop;
 
 my $loop = Mojo::IOLoop->new;
 
 my $future = Future::Mojo->new($loop);
 
 $loop->timer(3 => sub { $future->done('Done') });
 
 print $future->get, "\n";

=head1 DESCRIPTION

This subclass of L<Future> stores a reference to the associated L<Mojo::IOLoop>
instance, allowing the C<await> method to block until the Future is ready.

For a full description on how to use Futures, see the L<Future> documentation.

=head1 CONSTRUCTORS

=head2 new

 my $future = Future::Mojo->new;
 my $future = Future::Mojo->new($loop);

Returns a new Future. Uses L<Mojo::IOLoop/"singleton"> if no loop is specified.

=head2 new_timer

 my $future = Future::Mojo->new_timer($seconds);
 my $future = Future::Mojo->new_timer($loop, $seconds);

Returns a new Future that will become ready after the specified delay. Uses
L<Mojo::IOLoop/"singleton"> if no loop is specified.

=head2 new_timeout

 my $future = Future::Mojo->new_timeout($seconds);
 my $future = Future::Mojo->new_timeout($loop, $seconds);

Returns a new Future that will fail after the specified delay. Uses
L<Mojo::IOLoop/"singleton"> if no loop is specified.

=head1 METHODS

L<Future::Mojo> inherits all methods from L<Future> and implements the
following new ones.

=head2 loop

 $loop = $future->loop;

Returns the underlying L<Mojo::IOLoop> object.

=head2 await

 $future->await;

Runs the underlying L<Mojo::IOLoop> until the future is ready. If the event
loop is already running, an exception is thrown.

=head2 done_next_tick

 $future = $future->done_next_tick(@result);

A shortcut to calling the L<Future/"done"> method on the
L<Mojo::IOLoop/"next_tick">. Ensures that a returned Future object is not ready
immediately, but will wait for the next I/O round.

=head2 fail_next_tick

 $future = $future->fail_next_tick($exception, @details);

A shortcut to calling the L<Future/"fail"> method on the
L<Mojo::IOLoop/"next_tick">. Ensures that a returned Future object is not ready
immediately, but will wait for the next I/O round.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 CONTRIBUTORS

=over

=item Jose Luis Martinez (pplu)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Future>
