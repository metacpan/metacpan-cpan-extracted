package IO::AsyncX::SharedTimer;
# ABSTRACT: Low-accuracy shared timers for IO::Async
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.001';

=head1 NAME

IO::AsyncX::SharedTimer - provides L<IO::Async> timers which sacrifice accuracy for performance

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 # Needs to be added to a loop before you can
 # call any other methods
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $timer = IO::AsyncX::SharedTimer->new(
   # Combine timers into 50ms buckets, and
   # use cached value for ->now with 50ms expiry
   resolution => 0.050,
  )
 );

 # Report current time, accurate to ~50ms (defined
 # by the resolution parameter, as above)
 use feature qw(say);
 say "Time is roughly " . $timer->now;

 # Set a timeout for ~30s on an I/O operation
 Future->wait_any(
  $client->read_until(qr/\n/),
  $timer->timeout_future(after => 30)
 )->get;

=head1 DESCRIPTION

This module provides various time-related utility methods for use
with larger L<IO::Async> applications.

In situations where you have many related timers - connection expiry,
for example - there may be some overhead in having each of these in the
timer priority queue as a separate event. Sometimes the exact trigger
time is not so important, which is where this class comes in. You get
to specify an accuracy, and all timers which would occur within the
same window of time will be grouped together as a single timer event.

This may reduce calls to poll/epoll and timer management overhead, but
please benchmark the difference before assuming that this module will
be worth using - for some applications the overhead this introduces will
outweigh any potential benefits.

One benchmark gave the following results for 1ms resolution across 100
timers set to rand(1) seconds:

            Rate      normal   shared
 normal    32.9/s        --      -50%
 shared    65.7/s      100%        --

See the examples/ directory for code.

=cut

use Time::HiRes ();
use curry::weak;

=head1 METHODS

=cut

=head2 configure

Change the current resolution.

Takes one named parameter:

=over 4

=item * resolution - the resolution for timers and L</now>, in seconds

=back

=cut

sub configure {
	my ($self, %args) = @_;
	if(exists $args{resolution}) {
		$self->{resolution} = delete $args{resolution};
	}
	$self->SUPER::configure(%args);
}

=head2 resolution

Returns the current resolution.

=cut

sub resolution { shift->{resolution} }

=head2 now

Returns an approximation of the current time.

On first call, it will return (and cache) the value provided by
the L<Time::Hires> C<time> function.

Subsequent calls will return this same value. The cached value expires
after L</resolution> seconds - note that the expiry happens via the event
loop so if your code does not cede control back to the main event loop
in a timely fashion, the cached value will not expire. Put another way:
the value will be cached for at least L</resolution> seconds.

There's a good chance that the method call overhead will incur a heavier
performance impact than just calling L<Time::HiRes> C<time> directly.
As always, profile and benchmark first.

Example usage:

 my $start = $timer->now;
 $loop->run;
 my $elapsed = 1000.0 * ($timer->now - $start);
 say "Operation took about ${elapsed}ms to complete.";

=cut

sub now {
	my ($self) = @_;
	$self->{after} ||= ($self->loop or die "Must add this timer to a loop first")->delay_future(
		after => $self->resolution
	)->on_ready($self->curry::weak::expire);
	$self->{now} //= Time::HiRes::time;
}

=head2 delay_future

Returns a L<Future> which will resolve after approximately L</resolution> seconds.

See the C<delay_future> documentation in L<IO::Async::Loop> for more details.

=cut

=head2 timeout_future

Returns a L<Future> which will fail after approximately L</resolution> seconds.

See the C<delay_future> documentation in L<IO::Async::Loop> for more details.

=cut

BEGIN {
	for my $m (qw(delay_future timeout_future)) {
		no strict 'refs';
		*{__PACKAGE__ . '::' . $m} = sub {
			my ($self, %args) = @_;
			my $at = exists $args{at} ? delete $args{at} : $self->now + delete $args{after}
				or die "Invalid or unspecified time";
			# Resolution may change over time. We don't want to stomp on old values when this happens.
			# We also want to support both timeout+delay with the same values.
			my $bucket = join '-', $m, $self->resolution, int(($at - $^T) / $self->resolution);
			my $f = $self->loop->new_future;
			($self->{bucket}{$bucket} ||= $self->loop->$m(at => $at)->on_ready(sub {
				delete $self->{bucket}{$bucket}
			}))->on_ready($f);
			$f
		};
	}
}

sub expire {
	my ($self) = @_;
	delete @{$self}{qw(now after)};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
