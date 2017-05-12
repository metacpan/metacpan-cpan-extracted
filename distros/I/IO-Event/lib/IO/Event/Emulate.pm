
#
# Use a pure-perl event handler that kinda emulates's Event 
# for IO::Event's event handler.
#

my $sdebug = 0;

{
package IO::Event::Emulate;

use strict;
use warnings;

our @ISA = qw(IO::Event::Common);

my %want_read;
my %want_write;
my %want_exception;
my %active;

my $rin = '';
my $win = '';
my $ein = '';

my $unloop;

sub import
{
	require IO::Event;
	IO::Event->import('emulate_Event');
}

sub new
{
	my ($pkg, @stuff) = @_;
	$pkg->SUPER::new(@stuff);
}

# a replacement for Event::loop
sub ie_loop
{
	$unloop = 0;
	my ($rout, $wout, $eout);
	for(;;) {
		print STDERR "EMULATE LOOP-TOP\n" if $sdebug;
		last if $unloop;

		my $timer_timeout = IO::Event::Emulate::Timer->get_time_to_timer;

		my $timeout = $timer_timeout || IO::Event::Emulate::Idle->get_time_to_idle;

		if ($sdebug > 3) {
			print STDERR "Readers:\n";
			for my $ioe (values %want_read) {
				print STDERR "\t${*$ioe}{ie_desc}\n";
			}
			print STDERR "Writers:\n";
			for my $ioe (values %want_write) {
				print STDERR "\t${*$ioe}{ie_desc}\n";
			}
			print STDERR "Exceptions:\n";
			for my $ioe (values %want_exception) {
				print STDERR "\t${*$ioe}{ie_desc}\n";
			}
		}
		my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
		print STDERR "SELECT: N$nfound\n" if $sdebug;
		if ($nfound) {
			EVENT:
			{
				if ($rout) {
					for my $ioe (values %want_read) {
						next unless vec($rout, ${*$ioe}{ie_fileno}, 1);
						my $ret = $ioe->ie_dispatch_read(${*$ioe}{ie_fh});
						if ($ret && vec($wout, ${*$ioe}{ie_fileno}, 1)) {
							vec($wout, ${*$ioe}{ie_fileno}, 1) = 0;
							$nfound--;
						}
						if ($ret && vec($eout, ${*$ioe}{ie_fileno}, 1)) {
							vec($eout, ${*$ioe}{ie_fileno}, 1) = 0;
							$nfound--;
						}
						$nfound--;
						last EVENT unless $nfound > 0;
					}
				}
				if ($wout) {
					for my $ioe (values %want_write) {
						next unless vec($wout, ${*$ioe}{ie_fileno}, 1);
						my $ret = $ioe->ie_dispatch_write(${*$ioe}{ie_fh});
						if ($ret && vec($eout, ${*$ioe}{ie_fileno}, 1)) {
							vec($eout, ${*$ioe}{ie_fileno}, 1) = 0;
							$nfound--;
						}
						$nfound--;
						last EVENT unless $nfound > 0;
					}
				}
				if ($eout) {
					for my $ioe (values %want_exception) {
						next unless vec($eout, ${*$ioe}{ie_fileno}, 1);
						$ioe->ie_dispatch_exception(${*$ioe}{ie_fh});
						$nfound--;
						last EVENT unless $nfound > 0;
					}
				}
			}
		}
		IO::Event::Emulate::Timer->invoke_timers if $timer_timeout;
		IO::Event::Emulate::Idle->invoke_idlers($nfound == 0);
	}
	die unless ref($unloop);
	my @r = @$unloop;
	shift(@r);
	return $r[0] if @r == 1;
	return @r;
}

sub loop
{
	ie_loop(@_);
}

sub timer
{
	shift;
	IO::Event::Emulate::Timer->new(@_);
}

sub idle
{
	shift;
	IO::Event::Emulate::Idle->new(@_);
}

sub unloop_all
{
	$unloop = [1, @_];
}

sub set_write_polling
{
	my ($self, $new) = @_;
	my $fileno = ${*$self}{ie_fileno};
	if ($new) {
		vec($win, $fileno, 1) = 1;
		$want_write{$fileno} = $want_exception{$fileno} = $self;
	} else {
		vec($win, $fileno, 1) = 0;
		delete $want_write{$fileno};
		delete $want_exception{$fileno}
			unless $want_read{$fileno};
	}
	$ein = $rin | $win;
}

sub set_read_polling
{
	my ($self, $new) = @_;
	my $fileno = ${*$self}{ie_fileno};
	if ($new) {
		vec($rin, $fileno, 1) = 1;
		$want_read{$fileno} = $want_exception{$fileno} = $self;
	} else {
		if (defined $fileno) {
			vec($rin, $fileno, 1) = 0;
			delete $want_read{$fileno};
			delete $want_exception{$fileno}
				unless $want_write{$fileno}
		}
	}
	$ein = $rin | $win;
}

sub ie_register
{
	my ($self) = @_;
	my ($fh, $fileno) = $self->SUPER::ie_register();
	$active{$fileno} = $self;
	$self->readevents(! ${*$self}{ie_readclosed}); 
	$self->writeevents(0);
}

sub ie_deregister
{
	my ($self) = @_;
	$self->SUPER::ie_deregister();
	delete $active{${*$self}{ie_fileno}};
}

}{package IO::Event::Emulate::Timer;

use warnings;
use strict;
use Time::HiRes qw(time);
use Carp qw(confess);
use Scalar::Util qw(reftype);

our @ISA = qw(IO::Event);
our %timers = ();
our %levels = ();
our %next = ();

BEGIN {
	for $a (qw(at after interval hard cb desc prio repeat timeout)) {
		my $attrib = $a;
		no strict 'refs';
		*{"IO::Event::Emulate::Timer::$a"} = sub {
			my $self = shift;
			return $self->{$attrib} unless @_;
			my $val = shift;
			$self->{$attrib} = $val;
			return $val;
		};
	}
}

my $tcount = 1;

my @timers;

sub get_time_to_timer
{
	@timers = sort { $a <=> $b } keys %next;
	my $t = time;
	if (@timers) {
		if ($timers[0] > $t) {
			my $timeout = $timers[0] - $t;
			$timeout = 0.01 if $timeout < 0.01;
			return $timeout;
		} else {
			return 0.01;
		}
	}
	return undef;
}

sub invoke_timers
{
	while (@timers && $timers[0] < time) {
		print STDERR "Ti" if $sdebug;
		my $t = shift(@timers);
		my $te = delete $next{$t};
		for my $tnum (keys %$te) {
			my $timer = $te->{$tnum};
			next unless $timer->{next};
			next unless $timer->{next} eq $t;
			$timer->now();
		}
	}
}

sub new
{
	my ($pkg, %param) = @_;
	confess unless $param{cb};
	die if $param{after} && $param{at};
	my $timer = bless {
		tcount		=> $tcount,
		last_time	=> time,
		%param
	}, __PACKAGE__;
	$timers{$tcount++} = $timer;
	$timer->schedule;
	return $timer;
}

sub schedule
{
	my ($self) = @_;
	my $next;
	if ($self->{invoked}) {
		if ($self->{interval}) {
			$next = $self->{last_time} + $self->{interval};
			if ($self->{hard} && $self->{next}) {
				$next = $self->{next} + $self->{interval};
			}
		} else {
			$next = undef;
		}
	} elsif ($self->{at}) {
		$next = $self->{at};
	} elsif ($self->{after}) {
		$next = $self->{after} + time;
	} elsif ($self->{interval}) {
		$next = $self->{interval} + time;
	} else {
		die;
	}
	if ($next) {
		$next{$next}{$self->{tcount}} = $self;
		$self->{next} = $next;
	} else {
		$self->{next} = 0;
		$self->stop();
	}
}

sub start
{
	my ($self) = @_;
	$timers{$self->{tcount}} = $self;
	delete $self->{stopped};
	$self->schedule;
}

sub again
{
	my ($self) = @_;
	$self->{last_time} = time;
	$self->start;
}

sub now
{
	my ($self) = @_;
	$self->{last_time} = time;
	local($levels{$self->{tcount}}) = ($levels{$self->{tcount}} || 0)+1;
	$self->{invoked}++;
	if (reftype($self->{cb}) eq 'CODE') {
		$self->{cb}->($self);
	} elsif (reftype($self->{cb}) eq 'ARRAY') {
		my ($o, $m) = @{$self->{cb}};
		$o->$m($self);
	} else {
		die;
	}
	$self->schedule;
}


sub stop
{
	my ($self) = @_;
	delete $timers{$self->{tcount}};
	$self->{stopped} = time;
}

sub cancel
{
	my ($self) = @_;
	$self->{cancelled} = time;
	delete $timers{$self->{tcount}};
}

sub is_cancelled
{
	my ($self) = @_;
	return $self->{cancelled};
}

sub is_active
{
	my ($self) = @_;
	return exists $timers{$self->{tcount}};
}

sub is_running
{
	my ($self) = @_;
	return $levels{$self->{tcount}};
}

sub is_suspended
{
	my ($self) = @_;
	return 0;
}

sub pending
{
	return;
}


}{package IO::Event::Emulate::Idle;

use warnings;
use strict;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use Time::HiRes qw(time);

our @ISA = qw(IO::Event);
our %timers = ();
our %levels = ();
our %next = ();

my $icount = 0;
my %idlers;

our $time_to_idle_timeout = 1;

sub new
{
	my ($pkg, %param) = @_;
	confess unless $param{cb};
	die if $param{after} && $param{at};
	my $idler = bless {
		icount		=> $icount,
		last_time	=> time,
		%param
	}, __PACKAGE__;
	$idlers{$icount++} = $idler;
	return $idler;
}

sub get_time_to_idle
{
	return undef unless %idlers;
	return $time_to_idle_timeout;
}

sub start
{
	my ($self) = @_;
	$idlers{$self->{icount}} = $self;
	delete $self->{stopped};
	$self->schedule;
}

sub again
{
	my ($self) = @_;
	$self->{last_time} = time;
	$self->start;
}

sub invoke_idlers
{
	my ($pkg, $is_idle) = @_;
	for my $idler (values %idlers) {
		if ($idler->{min} && (time - $idler->{last_time}) < $idler->{min}) {
			next;
		}
		unless ($is_idle) {
			next unless $idler->{max};
			next unless (time - $idler->{last_time}) > $idler->{max};
		}
		$idler->now;
	}
}

sub now
{
	my ($self) = @_;
	$self->{last_time} = time;
	local($levels{$self->{icount}}) = ($levels{$self->{icount}} || 0)+1;
	if (defined($self->{reentrant}) && ! $self->{reentrant} && $self->{icount}) {
		return;
	}
	$self->{invoked}++;
	if (defined($self->{repeat}) && ! $self->{repeat}) {
		$self->cancel;
	}
	if (reftype($self->{cb}) eq 'CODE') {
		$self->{cb}->($self);
	} elsif (reftype($self->{cb}) eq 'ARRAY') {
		my ($o, $m) = @{$self->{cb}};
		$o->$m($self);
	} else {
		die;
	}
	$self->{last_time} = time;
}


sub stop
{
	my ($self) = @_;
	delete $idlers{$self->{icount}};
	$self->{stopped} = time;
}

sub cancel
{
	my ($self) = @_;
	$self->{cancelled} = time;
	delete $idlers{$self->{icount}};
}

sub is_cancelled
{
	my ($self) = @_;
	return $self->{cancelled};
}

sub is_active
{
	my ($self) = @_;
	return exists $idlers{$self->{icount}};
}

sub is_running
{
	my ($self) = @_;
	return $levels{$self->{icount}};
}

sub is_suspended
{
	my ($self) = @_;
	return 0;
}

sub pending
{
	return;
}


}#end package
1;
