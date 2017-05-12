# $Id: Throttle.pm,v 1.4 2010/03/12 22:10:11 dk Exp $
package IO::Lambda::Throttle;
use strict;
use warnings;
use Exporter;
use IO::Lambda qw(:all);
use IO::Lambda::Mutex qw(mutex);
use Time::HiRes qw(time);
use Scalar::Util qw(weaken);
our $DEBUG = $IO::Lambda::DEBUG{throttle} || 0;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(throttle);
our %EXPORT_TAGS = ( all => \@EXPORT_OK);

sub new
{
	my ($class, $rate, $strict) = @_;
	my $self = bless {
		mutex     => IO::Lambda::Mutex-> new,
		last      => 0,
		low       => 0,
		high      => 0,
		strict    => $strict || 0,
	}, $class;
	$self-> rate($rate);
	return $self;
}

sub rate
{
	return $_[0]-> {rate} unless $#_;
	my ( $self, $rate) = @_;
	die "negative rate" if defined($rate) and $rate < 0;
	$self-> {rate} = $rate;
}

sub strict { $#_ ? $_[0]-> {strict} = $_[1] : $_[0]-> {strict} }

# warning: when called, changes internal state of an object
# returns 0 if rate limitter thinks it's ok to run now,
# otherwise returns number of seconds needed to sleep
sub next_timeout
{
	my $self = shift;
	unless ( $self-> {rate}) {
		# special case
		return 0;
	}

	my $ts = time;
	if ( $ts < $self-> {last}) {
		# warn "negative time detected\n";
		my $delta = $self-> {last} - $ts;
		$self-> {low}  -= $delta;
		$self-> {high} -= $delta;
	}
	$self-> {last} = $ts;
	warn "$ts: $self->{low}/$self->{high}\n" if $DEBUG;

	if ( $self-> {low} < $self-> {high}) {
		$self-> {low} += 1 / $self-> {rate};
		warn "case1\n" if $DEBUG;
		return 0;
	} elsif ( $self-> {low} < $ts) {
		$self-> {low}  = $ts + 1 / $self-> {rate};
		$self-> {high} = $ts + ($self->{strict} ? 1 / $self-> {rate} : 1);
		warn "case2\n" if $DEBUG;
		return 0;
	} else {
		warn "wait ", $self->{low}-$ts, "\n" if $DEBUG;
		return $self-> {low} - $ts;
	}
}

# Returns a lambda that finishes until rate-limitter allows further run.
sub lock
{
	my $self = shift;
	weaken $self;
	return $self-> {mutex}-> pipeline( 
		lambda {
			my $timeout = $self-> next_timeout;
			return unless $timeout;
			context $timeout;
			timeout {
				die "something wrong, non-zero timeout"
					if $self-> next_timeout;
				return;
			};
		} 
	);
}

# returns a lambda that is finished when all lambdas, one by one,
# are passed through a rate limitter
sub ratelimit
{
	my ($self) = @_;
	my @ret;
	return lambda {
		my @lambdas = @_;
		return unless @lambdas;
		context $self-> lock;
		tail {
			context shift @lambdas;
		tail {
			push @ret, @_;
			if ( @lambdas) {
				this-> call(@lambdas)-> start;
			} else {
				my @r = @ret;
				@ret = ();
				return @r;
			}
		}}
	};
}


sub throttle { __PACKAGE__-> new(@_)-> ratelimit }

1;

=pod

=head1 NAME

IO::Lambda::Throttle - rate-limiting facility

=head1 DESCRIPTION

Provides several interfaces for throttling control flow by imposing rate limit.

=head1 SYNPOSIS

   use IO::Lambda qw(:lambda);
   use IO::Lambda::Throttle qw(throttle);

   # execute 2 lambdas a sec - blocking
   throttle(2)-> wait(@lambdas);
   # non-blocking
   lambda {
   	context throttle(2), @lambdas;
   	tail {};
   };

   # share a rate-limiter between two sets of lambdas running in parallel
   # strictly 1 lambda in 10 seconds will be executed
   my $t = IO::Lambda::Throttle-> new(0.1);

   # throttle lambdas sequentially
   sub track
   {
      my @lambdas = @_;
      return lambda {
         context $t-> ratelimit, @lambdas; 
         tail {};
      };
   }

   # parallel two tracks - execution order will be
   # $a[0], $b[0], $a[1], $b[1], etc
   lambda {
   	context track(@a), track(@b);
	tails {}
   }-> wait;

=head1 API

=over

=item new($rate = 0, $strict = 0)

The constructor creates a new rate-limiter object. The object methods (see
below) generate lambdas that allow to execute lambdas with a given rate and
algorithm. See L<rate> and C<strict> for description.

=item rate INT

C<$rate> is given in lambda/seconds, and means infinity if is 0.

=item strict BOOL

C<$strict> selects between fair and aggressive throttling . For example, if
rate is 5 l/s, and first 5 lambdas all come within first 0.1 sec. With
C<$strict> 0, all af them will be scheduled to execution immediately, but the
6th lambda will be delayed to 1.2 sec. With C<$strict> 1, all lambdas will be
scheduled to be executed evenly with 0.2 sec delay.

=item next_timeout :: TIMEOUT

Internal function, called when code needs to determine whether lambda is
allowed to run immediately (function returns 0) or after a timeout (returns
non-zero value).  If a non-zero value is returned, it is guaranteed that after
sleeping this time, next invocation of the function will return 0.

Override the function for your own implementation of rate-limiting function.

=item lock

Returns a lambda that will execute when rate-limiter allows next execution:

    context $throttle-> lock;
    tail {
         ... do something ...
    }

The lambda can be reused.

=item ratelimit :: @lambdas -> @ret

Returns a lambda that finishes when all passed @lambdas are finished.
Executes them one by one, imposing a rate limit. Returns results of lambdas
accumulated in a list.

=item throttle($rate,$strict)

Condition version of C<< new($rate,$strict)-> ratelimit >>

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
