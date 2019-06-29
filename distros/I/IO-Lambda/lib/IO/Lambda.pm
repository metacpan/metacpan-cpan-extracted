# $Id: Lambda.pm,v 1.191 2012/01/13 06:41:28 dk Exp $
package IO::Lambda;

use Carp qw(croak confess);
use strict;
use warnings;
use Exporter;
use Sub::Name;
use Scalar::Util qw(weaken);
use Time::HiRes qw(time);
use vars qw(
	$LOOP %EVENTS @LOOPS
	$VERSION @ISA
	@EXPORT_OK %EXPORT_TAGS	@EXPORT_CONSTANTS @EXPORT_LAMBDA @EXPORT_STREAM
	@EXPORT_DEV @EXPORT_FRAME @EXPORT_MISC @EXPORT_FUNC
	$THIS @CONTEXT $METHOD $CALLBACK $AGAIN $SIGTHROW
	$DEBUG_IO $DEBUG_LAMBDA $DEBUG_CALLER %DEBUG
);
$VERSION     = '1.29';
@ISA         = qw(Exporter);
@EXPORT_CONSTANTS = qw(
	IO_READ IO_WRITE IO_EXCEPTION 
	WATCH_OBJ WATCH_DEADLINE WATCH_LAMBDA WATCH_CALLBACK
	WATCH_IO_HANDLE WATCH_IO_FLAGS WATCH_CALLER WATCH_CANCEL
);
@EXPORT_STREAM = qw(
	sysreader syswriter getline readbuf writebuf
);
@EXPORT_LAMBDA = qw(
	this context lambda again state restartable catch autocatch 
	io readable writable rwx timeout tail tails tailo any_tail
);
@EXPORT_FUNC = qw(
	seq par mapcar filter fold curry 
);
@EXPORT_MISC    = qw(
	delete_frame set_frame get_frame swap_frame sigthrow
);
@EXPORT_DEV    = qw(
	_subname _o _t
);
@EXPORT_OK   = (
	@EXPORT_LAMBDA, @EXPORT_CONSTANTS, @EXPORT_STREAM, 
	@EXPORT_DEV, @EXPORT_MISC, @EXPORT_FUNC,
);
%EXPORT_TAGS = (
	func      => \@EXPORT_FUNC, 
	lambda    => \@EXPORT_LAMBDA, 
	stream    => \@EXPORT_STREAM, 
	constants => \@EXPORT_CONSTANTS,
	dev       => \@EXPORT_DEV,
	all       => [ @EXPORT_LAMBDA, @EXPORT_STREAM, @EXPORT_CONSTANTS, @EXPORT_FUNC ],
);

if ( exists $ENV{IO_LAMBDA_DEBUG}) {
	for my $p ( split ',', $ENV{IO_LAMBDA_DEBUG}) {
		if ( $p =~ /^([^=]+)=(.*)$/) {
			$DEBUG{lc $1}=$2;
		} else {
			$DEBUG{lc $p}++;
		}
	}
	$DEBUG_IO     = $DEBUG{io}     || 0;
	$DEBUG_LAMBDA = $DEBUG{lambda} || 0;
	$DEBUG_CALLER = $DEBUG{caller} || 0;
	$IO::Lambda::Loop::DEFAULT = $DEBUG{loop} if $DEBUG{loop};
	$SIG{__DIE__} = sub {
		return if $^S;
		Carp::confess(@_);
	} if $DEBUG{die};
}

use constant IO_READ         => 4;
use constant IO_WRITE        => 2;
use constant IO_EXCEPTION    => 1;
	
use constant WATCH_OBJ       => 0;
use constant WATCH_CANCEL    => 1;

use constant WATCH_DEADLINE  => 2;
use constant WATCH_LAMBDA    => 2;
use constant WATCH_CALLBACK  => 3;

use constant WATCH_CALLER    => 4;
use constant WATCH_IO_HANDLE => 4;
use constant WATCH_IO_FLAGS  => 5;

sub new
{
	IO::Lambda::Loop-> new unless $LOOP;
	return bless {
		in      => [],    # events we wait for 
		last    => [],    # result of the last state
		stopped => 0,     # initial state
		start   => $_[1], # kick-start coderef
	}, $_[0];
}

sub DESTROY
{
	my $self = $_[0];
	$self-> cancel_all_events;
}

my  $_doffs = 0;
sub _d_in  { $_doffs++ }
sub _d_out { $_doffs-- if $_doffs }
sub _d     { ('  ' x $_doffs), _obj(shift), ': ', @_, "\n" }
sub _o     { $_[0] =~ /0x([\w]+)/; $1 }
sub _obj   { "lambda(". _o($_[0]) . ")." . ( $_[0]->{caller} || '()' ) }
sub _t     { defined($_[0]) ? ( "time(", (($_[0] < 1_000_000) ? $_[0] : $_[0]-time()), ")" ) : () }
sub _ev
{
	$_[0] =~ /0x([\w]+)/;
	"event($1) ",
	(($#{$_[0]} == WATCH_IO_FLAGS) ? (
		'fd=', 
		fileno($_[0]->[WATCH_IO_HANDLE]), 
		' ',
		( $_[0]->[WATCH_IO_FLAGS] ? (
			join('/',
				(($_[0]->[WATCH_IO_FLAGS] & IO_READ)      ? 'read'  : ()),
				(($_[0]->[WATCH_IO_FLAGS] & IO_WRITE)     ? 'write' : ()),
				(($_[0]->[WATCH_IO_FLAGS] & IO_EXCEPTION) ? 'exc'   : ()),
			)) : 
			'timeout'
		),
		' ', _t($_[0]->[WATCH_DEADLINE]),
	) : (
		ref($_[0]-> [WATCH_LAMBDA]) ?
			_obj($_[0]-> [WATCH_LAMBDA]) :
			_t($_[0]->[WATCH_DEADLINE])
	))
}
sub _msg
{
	my $self = shift;
	_d(
		$self,
		"@_ >> (",
		join(',', 
			map { 
				defined($_) ? $_ : 'undef'
			} 
			@{$self->{last}}
		),
		')'
	)
}

#
# Part I - Object interface to callback and 
# messaging interface with event loop and lambdas
#
#########################################################

# register an IO event
sub watch_io
{
	my ( $self, $flags, $handle, $deadline, $callback, $cancel) = @_;

	confess "can't register events on a stopped lambda" if $self-> {stopped};
	confess "bad io flags" if 0 == ($flags & (IO_READ|IO_WRITE|IO_EXCEPTION));

	$deadline += time if defined($deadline) and $deadline < 1_000_000_000;
	
	my $rec = [
		$self,
		$cancel,
		$deadline,
		$callback,
		$handle,
		$flags,
	];
	weaken $rec->[0];
	push @{$self-> {in}}, $rec;

	warn _d( $self, "> ", _ev($rec)) if $DEBUG_IO;

	$LOOP-> watch( $rec );

	return $rec;
}

# register a timeout
sub watch_timer
{
	my ( $self, $deadline, $callback, $cancel) = @_;

	confess "can't register events on a stopped lambda" if $self-> {stopped};
	confess "$self: time is undefined" unless defined $deadline;
	
	$deadline += time if $deadline < 1_000_000_000;
	my $rec = [
		$self,
		$cancel,
		$deadline,
		$callback,
	];
	weaken $rec->[0];
	push @{$self-> {in}}, $rec;

	warn _d( $self, "> ", _ev($rec)) if $DEBUG_IO;

	$LOOP-> after( $rec);
	
	return $rec;
}

# register a callback when another lambda exits
sub watch_lambda
{
	my ( $self, $lambda, $callback, $cancel) = @_;
	@_ = (); # perl bug http://rt.perl.org/rt3//Public/Bug/Display.html?id=70974

	confess "can't register events on a stopped lambda" if $self-> {stopped};
	confess "bad lambda" unless $lambda and $lambda->isa('IO::Lambda');

	confess "won't watch myself" if $self == $lambda;
	# XXX check cycling
	
	$lambda-> reset if $lambda-> is_stopped;

	my $rec = [
		$self,
		$cancel,
		$lambda,
		$callback,
	];
	weaken $rec->[0];
	$rec-> [WATCH_CALLER] = Carp::shortmess if $DEBUG_CALLER;
	push @{$self-> {in}}, $rec;
	push @{$EVENTS{"$lambda"}}, $rec;

	$lambda-> start if $lambda-> is_passive;

	warn _d( $self, "> ", _ev($rec)) if $DEBUG_LAMBDA;

	return $rec;
}

# watch the watchers
sub override
{
	my ( $self, $method, $state, $cb) = ( 4 == @_) ? @_ : (@_[0,1],'*',$_[2]);

	if ( $cb) {
		$self-> {override}->{$method} ||= [];
		push @{$self-> {override}->{$method}}, [ $state, $cb ];
	} else {
		my $p;
		return unless $p = $self-> {override}->{$method};
		for ( my $i = $#$p; $i >= 0; $i--) {
			if (
				(
					not defined ($state) and 
					not defined ($p->[$i]-> [0])
				) or (
					defined($state) and 
					defined($p->[$i]-> [0]) and 
					$p->[$i]->[0] eq $state
				) 
			) {
				my $ret = splice( @$p, $i, 1);
				delete $self-> {override}->{$method} unless @$p;
				return $ret->[1];
			}
		}

		return undef;
	}
}

sub override_handler
{
	my ( $self, $method, $sub, $cb) = @_;

	my $o = $self-> {override}-> {$method}-> [-1];

	# check state match
	my ($a, $b) = ( $self-> {state}, $o-> [0]);
	unless (
		( not defined($a) and not defined ($b)) or
		( defined $a and defined $b and $a eq $b) or
		( defined $b and $b eq '*')
	) {
		# state not matched
		if ( 1 == @{$self-> {override}->{$method}}) {
			local $self-> {override}->{$method} = undef;
			return $sub-> ($cb);
		} else {
			pop @{$self-> {override}->{$method}};
			my $ret = $sub-> ($cb);
			push @{$self->{override}->{$method}}, $o;
			return $ret;
		}
	} else {
		# state matched
		local $self-> {super} = [ $sub, $cb ];
		if ( 1 == @{$self-> {override}->{$method}}) {
			local $self-> {override}->{$method} = undef;
			return $o-> [1]-> ( $self, $sub, $cb);
		} else {
			pop @{$self-> {override}->{$method}};
			my $ret = $o-> [1]-> ( $self, $sub, $cb);
			push @{$self->{override}->{$method}}, $o;
			return $ret;
		}
	}
}

# Insert a new callback to be called before original callback.
# Needs to insert callbacks in {override} stack in reverse order,
# because direct order serves LIFO order for override() callbacks, --
# and that means FIFO for intercept() callbacks. But we also want LIFO. 
sub intercept
{
	my ( $self, $method, $state, $cb) = ( 4 == @_) ? @_ : (@_[0,1],'*',$_[2]);
		
	return $self-> override( $method, $state, undef) unless $cb;

	_subname("intercept($method:$state)" => $cb);

	$self-> {override}->{$method} ||= [];
	unshift @{$self-> {override}->{$method}}, [ $state, sub {
		# this is called when lambda calls $method with $state
		my ( undef, $sub, $orig_cb) = @_;
		# $sub is a condition, like readable(&) or tail(&)
		$sub->( sub {
		# that (&) is finally called when IO event is there
			local $self-> {super} = [$orig_cb];
			&$cb;
		});
	} ];
}

sub super
{
	confess "super() call outside overridden condition" unless $_[0]-> {super};
	my $data = $_[0]-> {super};
	if ( defined $data-> [1]) {
		# override() super
		return $data-> [0]-> ($data-> [1]);
	} else {
		# intercept() super
		my $self = shift;
		return defined($data->[0]) ? 
			$data-> [0]-> (@_) :
			( wantarray ? @_ : $_[0] );
	}
}


# handle incoming asynchronous events
sub io_handler
{
	my ( $self, $rec) = @_;

	warn _d( $self, '< ', _ev($rec)) if $DEBUG_IO;

	my $in = $self-> {in};
	my $nn = @$in;
	@$in = grep { $rec != $_ } @$in;
	die _d($self, 'stray ', _ev($rec))
		if $nn == @$in or $self != $rec->[WATCH_OBJ];

	_d_in if $DEBUG_IO;
	local $self-> {cancel} = $rec-> [WATCH_CANCEL];
	@{$self->{last}} = $rec-> [WATCH_CALLBACK]-> (
		$self, 
		(($#$rec == WATCH_IO_FLAGS) ? $rec-> [WATCH_IO_FLAGS] : ()),
		@{$self->{last}}
	) if $rec-> [WATCH_CALLBACK];

	_d_out if $DEBUG_IO;
	warn $self-> _msg('io') if $DEBUG_IO;

	unless ( @$in) {
		warn _d( $self, 'stopped') if $DEBUG_LAMBDA;
		$self-> {stopped}++;
	}
}

# handle incoming synchronous events 
sub lambda_handler
{
	my ( $self, $rec) = @_;

	warn _d( $self, '< ', _ev($rec)) if $DEBUG_LAMBDA;

	my $in = $self-> {in};
	my $nn = @$in;
	@$in = grep { $rec != $_ } @$in;
	die _d($self, 'stray ', _ev($rec))
		if $nn == @$in or $self != $rec->[WATCH_OBJ];

	my $lambda = $rec-> [WATCH_LAMBDA];
	die _d($self, 
		'handler called but ', _obj($lambda),
		' is not finished yet') unless $lambda-> {stopped};

	my $arr = $EVENTS{"$lambda"};
	@$arr = grep { $_ != $rec } @$arr;
	delete $EVENTS{"$lambda"} unless @$arr;

	_d_in if $DEBUG_LAMBDA;
				
	local $self-> {cancel} = $rec-> [WATCH_CANCEL];
	@{$self->{last}} = 
		$rec-> [WATCH_CALLBACK] ? 
			$rec-> [WATCH_CALLBACK]-> (
				$self, 
				@{$rec-> [WATCH_LAMBDA]-> {last}}
			) : 
			@{$rec-> [WATCH_LAMBDA]-> {last}};

	_d_out if $DEBUG_LAMBDA;
	warn $self-> _msg('tail') if $DEBUG_LAMBDA;

	unless ( @$in) {
		warn _d( $self, 'stopped') if $DEBUG_LAMBDA;
		$self-> {stopped} = 1;
	}
}

# Removes one event from queue
sub cancel_event
{
	my ( $self, $rec) = @_;

	return unless @{$self-> {in}};

	@{$self->{last}} = $rec-> [WATCH_CANCEL]->($self, @{$self->{last}})
		if $rec-> [WATCH_CANCEL];

	$LOOP-> remove_event($rec) if $LOOP;
	@{$self-> {in}} = grep { $_ != $rec } @{$self-> {in}};

	if ($rec->[WATCH_LAMBDA] and ref($rec->[WATCH_LAMBDA])) {
		my $arr = $EVENTS{$rec->[WATCH_LAMBDA]};
		if ( $arr) {
			@$arr = grep { $_ != $rec } @$arr;
			delete $EVENTS{$rec->[WATCH_LAMBDA]} unless @$arr;
		}
	}
	@$rec = ();

	return if @{$self->{in}};
	# that was the last event

	warn _d( $self, 'stopped') if $DEBUG_LAMBDA;
	$self-> {stopped} = 1;
	$_-> remove( $self) for @LOOPS;
}

# Removes all events bound to the object, notifies the interested objects.
# The object becomes stopped immediately, so no new events will be allowed to register.
sub cancel_all_events
{
	my $self = shift;

	$self-> {stopped} = 1;
	delete $self->{frames};

	return unless @{$self-> {in}};

	for ( grep { $_-> [WATCH_CANCEL] } reverse @{$self-> {in}}) {
		my $wc = $_-> [WATCH_CANCEL];
		$_-> [WATCH_CANCEL] = undef;
		@{$self->{last}} = $wc-> ($self, $_, @{$self->{last}})
	}

	$LOOP-> remove( $self) if $LOOP;
	$_-> remove($self) for @LOOPS;

	for my $rec ( @{$self->{in}}) {
		if ( ref($rec->[WATCH_LAMBDA])) {
			my $arr = $EVENTS{$rec->[WATCH_LAMBDA]};
			if ( $arr) {
				@$arr = grep { $_ != $rec } @$arr;
				delete $EVENTS{$rec->[WATCH_LAMBDA]} unless @$arr;
			}
		}
		@$rec = ();
	}

	@{$self-> {in}} = (); 
}

sub autorestart
{
	$#_ ?
		$_[0]-> {autorestart} = $_[1] :
		( exists($_[0]-> {autorestart}) ?
			$_[0]-> {autorestart} : 1)
}
sub is_stopped  { $_[0]-> {stopped}  }
sub is_waiting  { not($_[0]->{stopped}) and @{$_[0]->{in}} }
sub is_passive  { not($_[0]->{stopped}) and not(@{$_[0]->{in}}) }
sub is_active   { $_[0]->{stopped} or @{$_[0]->{in}} }

# reset the state machine
sub reset
{
	my $self = shift;

	$self-> cancel_all_events;
	@{$self-> {last}} = ();
	delete $self-> {stopped};
	warn _d( $self, 'reset') if $DEBUG_LAMBDA;
}

# start the state machine
sub start
{
	my $self = shift;

	confess "can't start active lambda, call reset() first" if $self-> is_active;

	warn _d( $self, 'started') if $DEBUG_LAMBDA;
	@{$self->{last}} = $self-> {start}-> ($self, @{$self->{last}})
		if $self-> {start};
	warn $self-> _msg('initial') if $DEBUG_LAMBDA;

	unless ( @{$self->{in}}) {
		warn _d( $self, 'stopped') if $DEBUG_LAMBDA;
		$self-> {stopped} = 1;
	}
}

# peek into the current state
sub peek { wantarray ? @{$_[0]->{last}} : $_[0]-> {last}-> [0] }

# pass initial parameters to lambda
sub call 
{
	my $self = shift;

	confess "can't call active lambda" if $self-> is_active;

	@{$self-> {last}} = @_;
	$self;
}

# abandon all states and stop with constant message
sub terminate
{
	my ( $self, @error) = @_;

	$self-> {last} = \@error;
	$self-> cancel_all_events;
	warn $self-> _msg('terminate') if $DEBUG_LAMBDA;
}

# propagate event destruction on all levels
sub destroy
{
	shift-> cancel_all_events( cascade => 1);
}

# synchronisation

# drives objects dependant on the other objects until all of them
# are stopped
sub drive
{
	my $changed = 1;
	my $executed = 0;
	warn "IO::Lambda::drive --------\n" if $DEBUG_LAMBDA;
	while ( $changed) {
		$changed = 0;

		# dispatch
		for my $rec ( map { @$_ } values %EVENTS) {
			next unless $rec->[WATCH_LAMBDA]-> {stopped};
			$rec->[WATCH_OBJ]-> lambda_handler( $rec);
			$changed = 1;
			$executed++;
		}
	warn "IO::Lambda::drive .........\n" if $DEBUG_LAMBDA and $changed;
	}
	warn "IO::Lambda::drive +++++++++\n" if $DEBUG_LAMBDA;

	return $executed;
}

# do one quant
sub yield
{
	my $nonblocking = shift;
	my $more_events = 0;

	# custom loops must not wait
	for ( @LOOPS) {
		next if $_-> empty;
		$_-> yield;
		$more_events = 1;
	}

	if ( drive) {
		# some callbacks we called, don't let them wait in sleep
		return 1;
	}

	# main loop waits, if anything
	unless ( $LOOP-> empty) {
		$LOOP-> yield( $nonblocking);
		$more_events = 1;
	}

	$more_events = 1 if keys %EVENTS;
	return $more_events;
}


# wait for one lambda to stop
sub wait
{
	my $self = shift;
	if ( $self-> is_passive) {
		$self-> call(@_);
		$self-> start;
	}
	my @frame = get_frame();
	yield while not $self-> {stopped};
	set_frame(@frame);
	return $self-> peek;
}

# wait for all lambdas to stop
sub wait_for_all
{
	my @objects = @_;
	return unless @objects;
	$_-> start for grep { $_-> is_passive } @objects;
	my @ret;
	my @frame = get_frame();
	while ( 1) {
		push @ret, map { $_-> peek } grep { $_-> {stopped} } @objects;
		@objects = grep { not $_-> {stopped} } @objects;
		last unless @objects;
		yield;
	}
	set_frame(@frame);
	return @ret;
}

# wait for at least one lambda to stop, return those that stopped
sub wait_for_any
{
	my @objects = @_;
	return unless @objects;
	$_-> start for grep { $_-> is_passive } @objects;
	my @frame = get_frame();
	while ( 1) {
		my @n = grep { $_-> {stopped} } @objects;
		return @n if @n;
		yield;
	}
	set_frame(@frame);
	return;
}

# run the event loop until no lambdas are left in the blocking state
sub run {
	my @frame = get_frame();
	do {} while yield 
	set_frame(@frame);
}

#
# Part II - Procedural interface to the lambda-style programming
#
#################################################################

sub _lambda_restart { die "lambda() is not restartable" }
sub lambda(&)
{
	my $cb  = _subname(lambda => $_[0]);
	my $l   = __PACKAGE__-> new( sub {
		# initial lambda code is usually executed by tail/tails inside another lambda,
		# so protect the upper-level context
		local *__ANON__ = "IO::Lambda::lambda::callback";
		local $THIS     = shift;
		local @CONTEXT  = ();
		local $CALLBACK = $cb;
		local $METHOD   = \&_lambda_restart;
		$cb ? $cb-> (@_) : @_;
	});
	if ( $DEBUG_CALLER) {
		if ( $DEBUG_CALLER > 1) {
			$l-> {caller} = Carp::longmess;
			chomp $l-> {caller};
			$l-> {caller} =~ s/^ at //;
		} else {
			$l-> {caller} = join(':', (caller)[1,2]);
		}
	}
	$l;
}

sub _subname
{
	subname(
		caller(1 + ($_[2] || 0)) .  '::_'.  $_[0], 
		$_[1]
	) if $DEBUG_CALLER and $_[1] and not $AGAIN; 
	return $_[1];
}

*io = \&lambda;

# re-enter the latest (or other) frame
sub again
{
	if ( @_ ) {
		my $name = shift;
		Carp::carp("no such frame:$name") unless exists $THIS->{frames}->{$name};
		($METHOD, $CALLBACK, @CONTEXT) = @{ $THIS->{frames}->{$name} };
		@CONTEXT = @_ if @_;
	}
	local $AGAIN = 1;
	defined($METHOD) ?
		$METHOD-> ($CALLBACK) :
		confess "again() outside of a restartable call" 
}

# define context
sub this        { @_ ? ($THIS, @CONTEXT)    = @_ : $THIS }
sub context     { @_ ? (@CONTEXT)           = @_ : @CONTEXT }
sub set_frame   { ( $THIS, $METHOD, $CALLBACK, @CONTEXT) = @_ }
sub get_frame   { ( $THIS, $METHOD, $CALLBACK, @CONTEXT) }
sub swap_frame  { my @f = get_frame; set_frame(@_); @f }
sub clear       { set_frame(); undef $AGAIN; }
sub delete_frame { delete $THIS->{frames}->{$_[0]} }

END { ( $THIS, $METHOD, $CALLBACK, @CONTEXT) = (); }

sub state($)
{
	my $this = ($_[0] && ref($_[0])) ? shift(@_) : this;
	@_ ? $this-> {state} = $_[0] : return $this-> {state};
}

sub restartable
{
	my $name = @_ ? $_[0] : join(':', caller);
	$THIS->{frames}->{$name} = [ $METHOD, $CALLBACK, @CONTEXT ];
	return $name;
}

# exceptions and backtracing
sub catch(&$)
{
	my ( $cb, $event) = @_;
	my $who = (caller(1))[3];
	my @ctx = @CONTEXT;
	confess "catch callback already defined" if $event-> [WATCH_CANCEL];
	$event->[WATCH_CANCEL] = $cb ? sub {
		local *__ANON__ = "$who\:\:catch" if $DEBUG_CALLER;
		$THIS     = shift;
		local $THIS-> {cancelled_event} = shift;
		local $THIS-> {cancelling} = 1;
		@CONTEXT  = @ctx;
		$METHOD   = undef;
		$CALLBACK = undef;
		$cb-> (@_);
	} : undef;

	# if throw() happened before we even get here
	$event->[WATCH_CALLBACK] = $event->[WATCH_CANCEL]
		if $event->[WATCH_CALLBACK] && $event->[WATCH_CALLBACK] == \&_throw;
	
	return $event;
}

sub call_again
{
	my $self = shift;
	confess "called outside catch()" unless $self-> {cancelled_event};
	my $cb = $self-> {cancelled_event}->[WATCH_CALLBACK];
	$cb->($self, @_) if $cb;
}

sub autocatch($)
{
	catch {
		this-> call_again;
		this-> throw(@_);
	} $_[0]
}

sub is_cancelling { $_[0]-> {cancelling} }

sub _throw
{
	my $self = shift;
	warn _d( $self, 'throw') if $DEBUG_LAMBDA;
	$self-> throw(@_);
}

sub throw
{
	my ( $self, @error) = @_;
	my @c = $self-> callers;
	$_-> [WATCH_CALLBACK] = $_->[WATCH_CANCEL] || \&_throw for @c;
	$self-> terminate(@error);
	$SIGTHROW->($self, @error) if $SIGTHROW and not @c;
	return @error;
}

sub sigthrow
{
	shift if defined($_[0]) and (not(ref $_[0]) or ref($_[0]) ne 'CODE');
	$SIGTHROW = $_[0] if @_;
	return $SIGTHROW;
}

sub callees      { @{ $EVENTS{ "$_[0]" } || [] } }
sub callers      { grep { $_[0] == $_-> [WATCH_LAMBDA] } map { @$_ } values %EVENTS }

sub backtrace
{
	require IO::Lambda::Backtrace;
	IO::Lambda::Backtrace-> new($_[0], Carp::shortmess);
}

#
# Conditions:
#

# common wrapper for declaration of handle-watching user conditions
sub add_watch
{
	my ($self, $cb, $method, $flags, $handle, $deadline, @ctx) = @_;
	my $who;
	$who = (caller(1))[3] if $DEBUG_CALLER;
	$self-> watch_io(
		$flags, $handle, $deadline,
		sub {
			local *__ANON__ = "$who\:\:callback" if $DEBUG_CALLER;
			$THIS     = shift;
			@CONTEXT  = @ctx;
			$METHOD   = $method;
			$CALLBACK = $cb;
			$cb ? $cb-> (@_) : @_;
		}, 
		($AGAIN ? delete($self-> {cancel}) : undef),
	)
}

# rwx($flags,$handle,$deadline)
sub rwx(&)
{
	return $THIS-> override_handler('rwx', \&rwx, shift)
		if $THIS-> {override}->{rwx};

	$THIS-> add_watch( 
		_subname(rwx => shift), \&rwx,
		@CONTEXT[0,1,2,0,1,2]
	)
}

# readable($handle,$deadline)
sub readable(&)
{
	return $THIS-> override_handler('readable', \&readable, shift)
		if $THIS-> {override}->{readable};

	$THIS-> add_watch( 
		_subname(readable => shift), \&readable, IO_READ, 
		@CONTEXT[0,1,0,1]
	)
}

# writable($handle,$deadline)
sub writable(&)
{
	return $THIS-> override_handler('writable', \&writable, shift)
		if $THIS-> {override}->{writable};
	
	$THIS-> add_watch( 
		_subname(writable => shift), \&writable, IO_WRITE, 
		@CONTEXT[0,1,0,1]
	)
}

# common wrapper for declaration of time-watching user conditions
sub add_timer
{
	my ($self, $cb, $method, $deadline, @ctx) = @_;
	my $who;
	$who = (caller(1))[3] if $DEBUG_CALLER;
	$self-> watch_timer(
		$deadline,
		sub {
			local *__ANON__ = "$who\:\:callback" if $DEBUG_CALLER;
			$THIS     = shift;
			@CONTEXT  = @ctx;
			$METHOD   = $method;
			$CALLBACK = $cb;
			$cb ? $cb-> (@_) : @_;
		},
		($AGAIN ? delete($self-> {cancel}) : undef),
	)
}

# timeout($deadline)
sub timeout(&)
{
	return $THIS-> override_handler('timeout', \&timeout, shift)
		if $THIS-> {override}->{timeout};
	$THIS-> add_timer( _subname(timeout => shift), \&timeout, @CONTEXT[0,0])
}

# common wrapper for declaration of single lambda-watching user conditions
sub add_tail
{
	my ($self, $cb, $method, $lambda, @ctx) = @_;
	my $who;
	$who = (caller(1))[3] if $DEBUG_CALLER;
	$self-> watch_lambda(
		$lambda,
		($cb ? sub {
			local *__ANON__ = "$who\:\:callback" if $DEBUG_CALLER;
			$THIS     = shift;
			@CONTEXT  = @ctx;
			$METHOD   = $method;
			$CALLBACK = $cb;
			$cb-> (@_);
		} : undef),
		($AGAIN ? delete($self-> {cancel}) : undef),
	);
}

# convert constant @param into a lambda
sub add_constant
{
	my ( $self, $cb, $method, @param) = @_;
	$self-> add_tail ( 
		_subname(constant => $cb), $method,
		lambda { @param },
		@CONTEXT
	);
}

# handle default condition logic given a lambda
sub condition
{
	my ( $self, $cb, $method, $name) = @_;

	return $THIS-> override_handler($name, $method, $cb)
		if defined($name) and $THIS-> {override}->{$name};
	
	my @ctx = @CONTEXT;

	my $who;
	if ( $DEBUG_CALLER) {
		$who = defined($name) ? $name : (caller(1))[3];
		_subname($who, $cb, 2);
	}

	$THIS-> watch_lambda( 
		$self, 
		$cb ? sub {
			local *__ANON__ = "$who\:\:callback" if $DEBUG_CALLER;
			$THIS     = shift;
			@CONTEXT  = @ctx;
			$METHOD   = $method;
			$CALLBACK = $cb;
			$cb-> (@_);
		} : undef
	);
}

# dummy sub for empty calls for tails() family
sub _empty
{
	my ($name, $method, $cb) = @_;
	my @ctx = context;
	$THIS-> watch_lambda( IO::Lambda-> new, sub {
		local *__ANON__ = "IO::Lambda::".$name."::callback";
		@CONTEXT  = @ctx;
		$METHOD   = $method;
		$CALLBACK = $cb;
		$cb-> ();
	}) if $cb;
}

# tail( $lambda, @param) -- initialize $lambda with @param, and wait for it
sub tail(&)
{
	return $THIS-> override_handler('tail', \&tail, shift)
		if $THIS-> {override}->{tail};
	
	my ( $lambda, @param) = context;
	return _empty(tail => \&tail, shift) unless $lambda;

	$lambda-> reset
		if $lambda-> is_stopped and $lambda-> autorestart;
	if ( @param) {
		$lambda-> call( @param);
	} else {
		$lambda-> call unless $lambda-> is_active;
	}
	$THIS-> add_tail( _subname(tail => shift), \&tail, $lambda, $lambda, @param);
}


# tails(@lambdas) -- wait for all lambdas to finish
sub tails(&)
{
	return $THIS-> override_handler('tails', \&tails, shift)
		if $THIS-> {override}->{tails};
	
	my $cb = _subname tails => $_[0];
	my @lambdas = context;
	my $n = $#lambdas;
	return _empty(tails => \&tails, $cb) unless @lambdas;

	my @ret;
	my $watcher;
	$watcher = sub {
		$THIS     = shift;
		push @ret, @_;
		return if $n--;

		local *__ANON__ = "IO::Lambda::tails::callback";
		@CONTEXT  = @lambdas;
		$METHOD   = \&tails;
		$CALLBACK = $cb;
		$cb ? $cb-> (@ret) : @ret;
	};
	my $this = $THIS;
	$this-> watch_lambda( $_, $watcher) for @lambdas;
}

# tailo(@lambdas) -- wait for all lambdas to finish, return ordered results
sub tailo(&)
{
	return $THIS-> override_handler('tailo', \&tailo, shift)
		if $THIS-> {override}->{tailo};
	
	my $cb = _subname tailo => $_[0];
	my @lambdas = context;
	my $n = $#lambdas;
	return _empty(tailo => \&tailo, $cb) unless @lambdas;

	my @ret;
	my $watcher;
	$watcher = sub {
		my $curr  = shift;
		$THIS     = shift;
		$ret[ $curr ] = \@_;
		return if $n--;

		local *__ANON__ = "IO::Lambda::tailo::callback";
		@CONTEXT  = @lambdas;
		$METHOD   = \&tailo;
		$CALLBACK = $cb;
		@ret = map { @$_ } @ret;
		$cb ? $cb-> (@ret) : @ret;
	};
	my $this = $THIS;
	for ( my $i = 0; $i < @lambdas; $i++) {
		my $d = $i;
		$this-> watch_lambda(
			$lambdas[$i], 
			sub { $watcher->($d, @_) }
		);
	};
}

# any_tail($deadline,@lambdas) -- wait for any lambda to finish within time
sub any_tail(&)
{
	return $THIS-> override_handler('any_tail', \&any_tail, shift)
		if $THIS-> {override}->{any_tail};
	
	my $cb = _subname any_tail => $_[0];
	my ( $deadline, @lambdas) = context;
	my $n = $#lambdas;
	return _empty(any_tail => \&any_tail, $cb) unless @lambdas;

	my ( @ret, @watchers);
	my $timer;
	
	$timer = $THIS-> watch_timer( $deadline, sub {
		local *__ANON__ = "IO::Lambda::any_tail::callback1";
		$THIS     = shift;
		@CONTEXT  = ($deadline, @lambdas);
		$METHOD   = \&any_tail;
		$CALLBACK = $cb;
		@ret = $cb-> (@ret) if $cb;
		$THIS-> cancel_event($_) for @watchers;
		return @ret;
	}) if defined $deadline;

	my $watcher;
	$watcher = sub {
		push @ret, shift;
		return if $n--;
		
		local *__ANON__ = "IO::Lambda::any_tail::callback2";
		$THIS = shift;
		@CONTEXT  = ($deadline, @lambdas);
		$METHOD   = \&any_tail;
		$CALLBACK = $cb;
		@ret = $cb-> (@ret) if $cb;
		$THIS-> cancel_event( $timer) if $timer;
		return @ret;
	};

	@watchers = map {
		my $l = $_;
		$THIS-> watch_lambda( $l, sub {
			$watcher->($l, @_);
		})
	} @lambdas;
}

#
# Part III - High order lambdas
#
################################################################

# fold($l) :: @b -> @c
# $l :: ($a,@b) -> @c
sub fold($)
{
	my $l = shift;
	lambda {
		my @q = @_;
		context $l, shift(@q), shift(@q);
	tail {
		return @_ unless @q;
		context $l, shift(@q), @_;
		again;
	}}
}

# mapcar($l) :: (@p) -> @r
sub mapcar($)
{
	my $lambda = shift;
	lambda {
		my @ret;
		my @p = @_;
		return unless @p;
		context $lambda, shift @p;
	tail {
		push @ret, @_;
		return @ret unless @p;
		context $lambda, shift @p;
		again;
	}}
}

# filter($l) :: (@p) -> @r
sub filter($)
{
	my $lambda = shift;
	lambda {
		my @ret;
		return unless @_;
		my @p = @_;
		my $p = shift @p;
		context $lambda, $p;
	tail {
		push @ret, $p if shift;
		return @ret unless @p;
		$p = shift @p;
		context $lambda, $p;
		again;
	}}
}

# curry(@a -> $l) :: @a -> @b
sub curry(&)
{
	my $cb = $_[0];
	lambda {
		context $cb->(@_);
		&tail();
	}
}

# seq() :: (@l) -> @m
sub seq { mapcar curry { shift } }

# par($max = 0) :: (@l) -> @m
sub par
{
	my $max = $_[0] || 0;

	lambda {
		my @q = @_;
		my @ret;
		$max = @q if $max < 1 or $max > @q;
		context map {
			lambda {
				return unless @q;
				context shift @q;
			tail {
				push @ret, @_;
				return unless @q;
				context shift @q;
				again;
			}}
		} 1 .. $max;
		tails { @ret }
	}
}


# sysread lambda wrapper
#
# ioresult    :: ($result, $error)
# sysreader() :: ($fh, $buf, $length, $deadline) -> ioresult
sub sysreader (){ lambda 
{
	my ( $fh, $buf, $length, $deadline) = @_;
	$$buf = '' unless defined $$buf;

	this-> watch_io( IO_READ, $fh, $deadline, subname _sysreader => sub {
		return undef, 'timeout' unless $_[1];
                local $SIG{PIPE} = 'IGNORE';
		my $n = sysread( $fh, $$buf, $length, length($$buf));
		if ( $DEBUG_IO) {
			warn "fh(", fileno($fh), ") read ", ( defined($n) ? "$n bytes" : "error $!"), "\n";
			warn substr( $$buf, length($$buf) - $n), "\n" if $DEBUG_IO > 1 and ($n || 0) > 0;
		}
		return undef, $! unless defined $n;
		return $n;
	})
}}

# syswrite() lambda wrapper
#
# syswriter() :: ($fh, $buf, $length, $offset, $deadline) -> ioresult
sub syswriter (){ lambda
{
	my ( $fh, $buf, $length, $offset, $deadline) = @_;

	this-> watch_io( IO_WRITE, $fh, $deadline, subname _syswriter => sub {
		return undef, 'timeout' unless $_[1];
                local $SIG{PIPE} = 'IGNORE';
		my $n = syswrite( $fh, $$buf, $length, $offset);
		if ( $DEBUG_IO) {
			warn "fh(", fileno($fh), ") wrote ", ( defined($n) ? "$n bytes out of $length" : "error $!"), "\n";
			warn substr( $$buf, $offset, $n), "\n" if $DEBUG_IO > 1 and ($n || 0) > 0;
		}
		return undef, $! unless defined $n;
		return $n;
	});
}}

sub _match 
{
	my ( $cond, $buf) = @_;

	return unless defined $cond;

	return ($$buf =~ /($cond)/)[0] if ref($cond) eq 'Regexp';
	return $cond->($buf) if ref($cond) eq 'CODE';
	return length($$buf) >= $cond;
}

# read from stream until condition is met
#
# readbuf($reader) :: ($fh, $$buf, $cond, $deadline) -> ioresult
sub readbuf
{
	my $reader = shift || sysreader;

	lambda {
		my ( $fh, $buf, $cond, $deadline) = @_;
		
		$$buf = "" unless defined $$buf;

		my $match = _match( $cond, $buf);
		return $match if $match;
	
		my ($maxbytes, $bufsize);
		$maxbytes = $cond - length($$buf)
			if defined($cond) and not ref($cond) and $cond > length($$buf);
		$bufsize = defined($maxbytes) ? $maxbytes : 65536;
		
		my $savepos = pos($$buf); # useful when $cond is a regexp

		context $reader, $fh, $buf, $bufsize, $deadline;
	tail {
		pos($$buf) = $savepos;

		my $bytes = shift;
		return undef, shift unless defined $bytes;
		
		unless ( $bytes) {
			return 1 unless defined $cond;
			return undef, 'eof';
		}
		
		# got line? return it
		my $match = _match( $cond, $buf);
		return $match if $match;
		
		# otherwise, just wait for more data
		$bufsize -= $bytes if defined $maxbytes;

		context $reader, $fh, $buf, $bufsize, $deadline;
		again;
	}}
}

# curry readbuf()
#
# getline($reader) :: ($fh, $$buf, $deadline) -> ioresult
sub getline
{
	my $reader = shift;
	lambda {
		my ( $fh, $buf, $deadline) = @_;
		confess "getline() needs a buffer! ( f.ex getline,\$fh,\\(my \$buf='') )"
			unless ref($buf);
		context readbuf($reader), $fh, $buf, qr/^[^\n]*\n/, $deadline;
	tail {
		substr( $$buf, 0, length($_[0]), '') unless defined $_[1];
		@_;
	}}
}

# write whole buffer to stream
#
# writebuf($writer) :: syswriter
sub writebuf
{
	my $writer = shift || syswriter;

	lambda {
		my ( $fh, $buf, $len, $offs, $deadline) = @_;

		my ( $written, $recheck_length, $olen) = (0);
		$$buf = "" unless defined $$buf;
		$offs = 0 unless defined $offs;
		unless ( defined $len) {
			$olen = $len = length $$buf;
			$recheck_length++;
		}
		
		context $writer, $fh, $buf, $len, $offs, $deadline;
	tail {
		my $bytes = shift;
		return undef, shift unless defined $bytes;

		$offs    += $bytes;
		$written += $bytes;
		$len     -= $bytes;
		if ( $recheck_length) {
			my $l = length $$buf;
			if ( $l > $olen) {
				$len  += $l - $olen;
				$olen = $l;
			}
		}
		return $written if $len <= 0;

		context $writer, $fh, $buf, $len, $offs, $deadline;
		again;
	}}
}

#
# Part IV - Developer API for custom condvars and event loops
#
################################################################

# register condvar listener
sub bind
{
	my $self = shift;

	# create new condition
	confess "can't register events on a stopped lambda" if $self-> {stopped};

	my $rec = [ $self, @_ ];
	push @{$self-> {in}}, $rec;

	return $rec;
}

# stop listening on a condvar
sub resolve
{
	my ( $self, $rec) = @_;

	my $in = $self-> {in};
	my $nn = @$in;
	@$in = grep { $rec != $_ } @$in;
	die _d($self, "stray condvar event $rec (@$rec)")
		if $nn == @$in or $self != $rec->[WATCH_OBJ];

	undef $rec-> [WATCH_OBJ]; # unneeded references

	unless ( @$in) {
		warn _d( $self, 'stopped') if $DEBUG_LAMBDA;
		$self-> {stopped} = 1;
		delete $self->{frames};
	}
}

sub callout
{
	my ( $self, $cb, @param) = @_;
	@{$self->{last}} = $cb ? $cb-> (@param) : @param;
}

sub add_loop     { push @LOOPS, shift }
sub remove_loop  { @LOOPS = grep { defined and $_ != $_[0] } @LOOPS }

sub __end        { clear(); undef %EVENTS; undef @LOOPS; } # for threads

package IO::Lambda::Loop;
use vars qw($DEFAULT);
use strict;
use warnings;

$DEFAULT = 'Select' unless defined $DEFAULT;
sub default { $DEFAULT = shift }

sub new
{
	return $IO::Lambda::LOOP if $IO::Lambda::LOOP;

	my ( $class, %opt) = @_;

	$opt{type} ||= $DEFAULT;
	$class .= "::$opt{type}";
	eval "use $class;";
	die $@ if $@;

	return $IO::Lambda::LOOP = $class-> new();
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda - non-blocking I/O as lambda calculus

=head1 SYNOPSIS

The code below demonstrates execution of parallel HTTP requests

   use strict;
   use IO::Lambda qw(:lambda :func);
   use IO::Socket::INET;

   # this function creates a new lambda object 
   # associated with one socket, and fetches a single URL
   sub http
   {
      my $host = shift;

      # Simple HTTP functions by first sending request to the remote, and
      # then waiting for the response. This sets up a new lambda object with 
      # attached one of many closures that process sequentially
      return lambda {

         # create a socket, and issue a tcp connect
         my $socket = IO::Socket::INET-> new( 
            PeerAddr => $host, 
            PeerPort => 80 
         );

         # Wait until socket become writable. Parameters to writable()
	 # are passed using context(). This association is remembered 
	 # within the engine. 
         context $socket;

         # writeable sets up a possible event to monitor, when 
	 # $socket is writeable, execute the closure.
      writable {
         # The engine discovered we can write, so send the request
         print $socket "GET /index.html HTTP/1.0\r\n\r\n";

         # This variable needs to stay shared across
	 # multiple invocations of our readable closure, so 
	 # it needs to be outside that closure. Here, it collects
         # whatever the remote returns
         my $buf = ''; 

	 # readable registers another event to monitor - 
	 # that $socket is readable. Note that we do not 
	 # need to set the context again because when we get 
	 # here, the engine knows what context this command 
	 # took place in, and assumes the same context. 
	 # Also note that socket won't be awaited for writable events
	 # anymore, and this code won't be executed for this $socket.
      readable {
         # This closure is executed when we can read.
         
	 # Read from the socket. sysread() returns number of
	 # bytes read. Zero means EOF, and undef means error, so
	 # we stop on these conditions.
         # If we return without registering a follow-up 
	 # handler, this return will be processed as the 
	 # end of this sequence of events for whoever is 
	 # waiting on us.
         return $buf unless 
            sysread( $socket, $buf, 1024, length($buf));

         # We're not done so we need to do this again. 
	 # Note that the engine knows that it just 
	 # called this closure because $socket was 
	 # readable, so it can infer that it is supposed 
	 # to set up a callback that will call this 
	 # closure when $socket is next readable.
         again;
      }}}
   }

   # Fire up a single lambda and wait until it completes.
   print http('www.perl.com')-> wait;

   # Fire up a lambda that waits for two http requests in parallel.
   # tails() can wait for more than one lambda
   my @hosts = ('www.perl.com', 'www.google.com');
   lambda {
      context map { http($_) } @hosts;
      # tails() asynchronously waits until all lambdas in the context
      # are finished.
      tails { print @_ }
   }-> wait;

   # crawl for all urls in parallel, but keep 10 parallel connections max
   print par(10)-> wait(map { http($_) } @hosts);
   
   # crawl for all urls sequentially
   print mapcar( curry { http(shift) })-> wait(@hosts);

Note: C<io> and C<lambda> are synonyms - I personally prefer C<lambda> but some
find the word slightly inappropriate, hence C<io>. See however L<Higher-order
functions> to see why it is more C<lambda> than C<io>.

=head1 DESCRIPTION

This module is another attempt to fight the horrors of non-blocking I/O.  It
tries to bring back the simplicity of the declarative programming style, that
is only available when one employs threads, coroutines, or co-processes.
Usually coding non-blocking I/O for single process, single thread programs
requires construction of state machines, often fairly complex, which fact
doesn't help the code clarity, and is the reason why the asynchronous I/O
programming is often considered 'messy'. Similar to the concept of monads in
functional languages, that enforce a certain order of execution over generally
orderless functions, C<IO::Lambda> allows writing I/O callbacks in a style that
resembles the good old sequential, declarative programming.

The manual begins with code examples, then proceeds to explaining basic
assumptions, then finally gets to the complex concepts, where the real fun
begins. You can skip directly there (L<Stream IO>, L<Higher-order functions>),
where the functional style mixes with I/O. If, on the contrary, you are
intimidated by the module's ambitions, you can skip to L<Simple use> for a more
gentle introduction. Those, who are interested how the module is different from
the other I/O frameworks, please continue reading.

=head2 Simple use

This section is for those who don't need all of the module's powerful
machinery. Simple callback-driven programming examples show how to use the
module for unsophisticated tasks, using concepts similar to the other I/O
frameworks. It is possible to use the module on this level only, however one
must be aware that by doing so, the real power of the higher-order abstraction
is not used.

C<IO::Lambda>, like all I/O multiplexing libraries, provides functions for
registering callbacks, that in turn are called when a timeout occurs, or when a
file handle is ready for reading and/or writing. See below code examples that
demonstrate how to program on this level of abstraction.

=over

=item Combination of two timeouts and an IO_READ event

   use IO::Lambda qw(:constants);

   my $obj = IO::Lambda-> new;

   # Either 3 or time + 3 will do. See "Time" section for more info
   $obj-> watch_timer( 3, sub { print "I've slept 3 seconds!\n" });

   # I/O flags is a combination of IO_READ, IO_WRITE, and IO_EXCEPTION.
   # Timeout is either 5 or time + 5, too.
   $obj-> watch_io( IO_READ, \*STDIN, 5, sub {
   	my ( $self, $ok) = @_;
	print $ok ?
	    "stdin is readable!\n" : 
	    "stdin is not readable within 5 seconds\n";
   });

   # main event loop is stopped when there are no lambdas and no 
   # pending events
   IO::Lambda::run;

=item Waiting for another lambda to complete
   
   use IO::Lambda;

   my $a = IO::Lambda-> new;
   $a-> watch_timer( 3, sub { print "I've slept 3 seconds!\n" });

   my $b = IO::Lambda-> new;
   # A lambda can wait for more than one event or lambda.
   # A lambda can be awaited by more than one lambda.
   $b-> watch_lambda( $a, sub { print "lambda #1 is finished!\n"});

   IO::Lambda::run;

=back

=head2 Example: reading lines from a filehandle

Given C<$filehandle> is non-blocking, the following code creates a lambda
object (later, simply a I<lambda>) that reads from the handle until EOF or an
error occured. Here, C<getline> (see L<Stream IO> below) constructs a lambda
that reads a single line from a filehandle.

    use IO::Lambda qw(:all);

    sub my_reader
    {
       my $filehandle = shift;
       lambda {
           context getline, $filehandle, \(my $buf = '');
       tail {
           my ( $string, $error) = @_;
           if ( $error) {
               warn "error: $error\n";
           } else {
               print $string;
               return again;
           }
       }}
    }

Assume we have two socket connections, and sockets are non-blocking - read from
both of them in parallel. The following code creates a lambda that reads from
two readers:

    sub my_reader_all
    {
        my @filehandles = @_;
	lambda {
	    context map { my_reader($_) } @filehandles;
	    tails { print "all is finished\n" };
	}
    }

    my_reader_all( $socket1, $socket2)-> wait;

=head2 Non-blocking HTTP client

Given a socket, create a lambda that implements the HTTP protocol

    use IO::Lambda qw(:all);
    use IO::Socket;
    use HTTP::Request;

    sub talk
    {
        my $req    = shift;
        my $socket = IO::Socket::INET-> new( PeerAddr => 'www.perl.com', PeerPort => 80);

	lambda {
	    context $socket;
	    writable {
	        # connected
		print $socket "GET ", $req-> uri, "\r\n\r\n";
		my $buf = '';
		readable {
		    sysread $socket, $buf, 1024, length($buf) or return $buf;
		    again; # wait for reading and re-do the block
		}
	    }
	}
    }

Connect and talk to the remote

    $request = HTTP::Request-> new( GET => 'http://www.perl.com');

    my $q = talk( $request );
    print $q-> wait; # will print content of $buf

Connect two parallel connections: by explicitly waiting for each 

    $q = lambda {
        context talk($request);
	tail { print shift };
        context talk($request2);
	tail { print shift };
    };
    $q-> wait;

Connect two parallel connections: by waiting for all

    $q = lambda {
        context talk($request1), talk($request2);
	tails { print for @_ };
    };
    $q-> wait;

Teach our simple http request to redirect by wrapping talk().
talk_redirect() will have exactly the same properties as talk() does

    sub talk_redirect
    {
        my $req = shift;
	lambda {
	    context talk( $req);
	    tail {
	        my $res = HTTP::Response-> parse( shift );
		return $res unless $res-> code == 302;

		$req-> uri( $res-> uri);
	        context talk( $req);
		again;
	    }
	}
    }

=head2 Full example code

    use strict;
    use IO::Lambda qw(:lambda);
    use IO::Socket::INET;

    sub get
    {
        my ( $socket, $url) = @_;
        lambda {
            context $socket;
        writable {
            print $socket "GET $url HTTP/1.0\r\n\r\n";
            my $buf = '';
        readable {
            my $n = sysread( $socket, $buf, 1024, length($buf));
            return "read error:$!" unless defined $n;
            return $buf unless $n;
            again;
        }}}
    }

    sub get_parallel
    {
        my @hosts = @_;

	lambda {
	   context map { get(
              IO::Socket::INET-> new(
                  PeerAddr => $_, 
                  PeerPort => 80 
              ), '/index.html') } @hosts;
	   tails {
	      join("\n\n\n", @_ )
	   }
	}
    }

    print get_parallel('www.perl.com', 'www.google.com')-> wait;

See tests and additional examples in directory C<eg/> for more information.

=head1 API

=head2 Events and states

A lambda is an C<IO::Lambda> object, that waits for I/O and timeout events, and
for events generated when other lambdas are completed. On each such event a
callback is executed. The result of the execution is saved, and passed on to the
next callback, when the next event arrives.

Life cycle of a lambda goes through three modes: passive, waiting, and stopped.
A lambda that is just created, or was later reset with C<reset> call, is in the
passive state.  When the lambda gets started, the only executed code will be
the callback associated with the lambda:

    $q = lambda { print "hello world!\n" };
    # not printed anything yet
    $q-> wait; # <- here it will

Lambdas are usually not started explicitly. Usually, the function that can wait
for a lambda, starts it too. C<wait>, the synchronous waiter, and
C<tail>/C<tails>, the asynchronous ones, start passive lambdas when called.
A lambda is I<finished> when there are no more events to listen to. The lambda
in the example above will finish right after C<print> statement.

Lambda can listen to events by calling I<conditions>, that internally subscribe
the lambda object to the corresponding file handles, timers, and other lambdas.
Most of the expressive power of C<IO::Lambda> lies in the conditions, such as
C<readable>, C<writable>, C<timeout>. Conditions are different from normal perl
subroutines in the way how they receive their parameters. The only parameter
they receive in the normal way, is the associated callback, while all other
parameters are passed to it through the alternate stack, by the explicit
C<context> call. 

In the example below, lambda watches for file handle readability:

    $q = lambda {
        context \*SOCKET;
	readable { print "I'm readable!\n"; }
	# here is nothing printed yet
    };
    # and here is nothing printed yet

Such lambda, when started, will switch to the waiting state, which means that
it will be waiting for the socket. The lambda will finish only after the
callback associated with C<readable> condition is called.  Of course, new event
listeners can be created inside all callbacks, on each state. This fact constitutes
another large benefit of C<IO::Lambda>, as it allows to program FSMs
dynamically.

The new event listeners can be created either by explicitly calling condition,
or by restarting the last condition with the C<again> call. For example, code

     readable { 
        print 1;
	again if int rand(2)
     }

prints indeterminable number of ones.

=head2 Contexts

All callbacks associated with a lambda object (further on, merely lambda)
execute in one, private context, also associated to the lambda. The context
here means that all conditions register callbacks on an implicitly given lambda
object, and keep the passed parameters on the context stack. The fact that
the context is preserved between states, helps building terser code with series of
IO calls:

    context \*SOCKET;
    writable {
    readable {
    }}

is actually the shorter form for

    context \*SOCKET;
    writable {
    context \*SOCKET; # <-- context here is retained from one frame up
    readable {
    }}

And as the context is bound to the current closure, the current lambda object
is too, in C<this> property. The code above is actually

    my $self = this;
    context \*SOCKET;
    writable {
    this $self;      # <-- object reference is retained here
    context \*SOCKET;
    readable {
    }}

C<this> can be used if more than one lambda needs to be accessed. In which case,

    this $object;
    context @context;

is the same as

    this $object, @context;

which means that explicitly setting C<this> will always clear the context.

=head2 Data and execution flow

A lambda is initially called with some arguments passed from the outside. These
arguments can be stored using the C<call> method; C<wait> and C<tail> also
issue C<call> internally, thus replacing any previous data stored by C<call>.
Inside the lambda these arguments are available as C<@_>.

Whatever is returned by a condition callback (including the C<lambda> condition
itself), will be passed further on as C<@_> to the next callback, or to the
outside, if the lambda is finished. The result of the finished lambda is
available by C<peek> method, that returns either all array of data available in
the array context, or first item in the array otherwise. C<wait> returns the
same data as C<peek> does.

When more than one lambda watches for another lambda, the latter will get its
last callback results passed to all the watchers. However, when a lambda
creates more than one state that derive from the current state, a forking
behaviour of sorts, the latest stored results gets overwritten by the first
executed callback, so constructions such as

    readable  { 1 + shift };
    writable { 2 + shift };
    ...
    wait(0)

will eventually return 3, but whether it will be 1+2 or 2+1, is undefined.

C<wait> is not the only function that synchronises input and output data.
C<wait_for_all> method waits for all lambdas, including the caller, to finish.
It returns collected results of all the objects in a single list.
C<wait_for_any> method waits for at least one lambda, from the list of passed
lambdas (again, including the caller), to finish. It returns list of finished
objects as soon as possible.

=head2 Time

Timers and I/O timeouts can be given not only in the timeout values, as it
usually is in event libraries, but also as deadlines in (fractional) seconds
since epoch. This decision, strange at first sight, actually helps a lot when
a total execution time is to be tracked. For example, the following code reads as
many bytes as possible from a socket within 5 seconds:

   lambda {
       my $buf = '';
       context $socket, time + 5;
       readable {
           if ( shift ) {
	       return again if sysread $socket, $buf, 1024, length($buf);
	   } else {
	       print "oops! a timeout\n";
	   }
	   $buf;
       }
   };

Rewriting the same code with C<readable> semantics that accepts time as a timeout
instead, would be not that elegant:

   lambda {
       my $buf = '';
       my $time_left = 5;
       my $now = time;
       context $socket, $time_left;
       readable {
           if ( shift ) {
	       if (sysread $socket, $buf, 1024, length($buf)) {
	           $time_left -= (time - $now);
		   $now = time;
		   context $socket, $time_left;
	           return again;
	       }
	   } else {
	       print "oops! a timeout\n";
	   }
	   $buf;
       }
   };

However, the exact opposite is true for C<timeout>. The following two lines
both sleep 5 seconds:

   lambda { context 5;        timeout {} }
   lambda { context time + 5; timeout {} }

Internally, timers use C<Time::HiRes::time> that gives the fractional number of
seconds. This however is not required for the caller, because when high-res
timers are not used, timeouts will simply be less precise, and will jitter
plus-minus half a second.

=head2 Conditions

All conditions receive their parameters from the context stack, or simply the
I<context>. The only parameter passed to them by using perl call, is the callback
itself. Conditions can also be called without a callback, in which case, they
will pass further data that otherwise would be passed as C<@_> to the
callback. Thus, a condition can be called either as

    readable { .. code ... }

or 

    &readable(); # no callback
    &readable;   # DANGEROUS!! same as &readable(@_)

Conditions can either be used after explicit exporting

   use IO::Lambda qw(:lambda);
   lambda { ... }

or by using the package syntax,

   use IO::Lambda;
   IO::Lambda::lambda { ... };

Note: If you know concept of continuation-passing style, this is exactly how
conditions work, except that closures are used instead of continuations
(Brock Wilcox:thanks!) .

=over

=item lambda()

Creates a new C<IO::Lambda> object.

=item io()

Same as C<lambda>.

=item readable($filehandle, $deadline = undef)

Executes either when C<$filehandle> becomes readable, or after C<$deadline>.
Passes one argument, which is either TRUE if the handle is readable, or FALSE
if time is expired. If C<deadline> is C<undef>, then no timeout is registered,
that means that it will never be called with FALSE.

=item writable($filehandle, $deadline = undef)

Exactly same as C<readable>, but executes when C<$filehandle> becomes writable.

=item rwx($flags, $filehandle, $deadline = undef)

Executes either when C<$filehandle> satisfies any of the condition in C<$flags>,
or after C<$deadline>. C<$flags> is a combination of three integer constants,
C<IO_READ>, C<IO_WRITE>, and C<IO_EXCEPTION>, that are imported by

   use IO::Lambda qw(:constants);

Passes one argument, which is either a combination of the same C<IO_XXX> flags,
that report which conditions the handle satisfied, or 0 if time is expired. If
C<deadline> is C<undef>, no timeout is registered, i.e. will never return 0.

=item timeout($deadline)

Executes after C<$deadline>. C<$deadline> cannot be C<undef>.

=item tail($lambda, @parameters)

Issues C<< $lambda-> call(@parameters) >>, then waits for the C<$lambda>
to complete. Since C<call> can only be done on inactive lambdas, will
fail if C<@parameters> is not empty and C<$lambda> is already running.

By default, C<tail> resets lambda if is was alredy finished. This
behavior can be changed by manipulating C<autorestart> property.

=item tails(@lambdas)

Executes when all objects in C<@lambdas> are finished, returns the collected,
unordered results of the objects.

=item tailo(@lambdas)

Same as C<tails>, but the results are ordered.

=item any_tail($deadline,@lambdas)

Executes either when all objects in C<@lambdas> are finished, or C<$deadline>
expires. Returns lambdas that were successfully executed during the allotted
time.

=item context @ctx

If called with no parameters, returns the current context, otherwise
replaces the current context with C<@ctx>. It is thus not possible 
(not that it is practical anyway) to clear the context with this call.
If really needed, use C<this(this)> syntax.

=item this $this, @ctx

If called with no parameters, returns the current lambda.
Otherwise, replaces both the current lambda and the current context.
Can be useful either when juggling with several lambdas, or as a
convenience hack over C<my> variables, for example,

    this lambda { ... };
    this-> wait;

instead of

    my $q = lambda { ... };
    $q-> wait;

=item condition $lambda, $callback, $method, $name

Helper function for creating conditions, either from lambdas 
or from lambda constructors.

Example: convert existing C<getline> constructor into a condition:

   sub gl(&) { getline-> call(context)-> condition( shift, \&gl, 'gl') }
   ...
   context $fh, $buf, $deadline;
   gl { ... }


=back

=head2 Frames

These are functions to jump to previous callback frames to
a previously saved context.
 
=over

=item again([$frame, [@context]])

Restarts the frame with the context.  If C<$frame> is given, jumps to the frame
previously returned by a C<restartable> call, resetting the context to its
previous state too.  If C<@context> is given, it is used instead.

All the conditions above, excluding C<lambda>, are restartable with C<again>
call (see C<start> for restarting a C<lambda>). The code

   context $obj1;
   tail {
       return if $null++;
       context $obj2;
       again;
   };

is thus equivalent to

   context $obj1;
   tail {
       context $obj2;
       &tail();
   };

C<again> passes the current context to the condition.

If C<$frame> is provided, then it is treated as result of previous C<restartable> call.
It contains data sufficient to restarting another call, instead of the current.
See L<Frames> for details.

=item restartable([$name])

Save a frame. C<restartable> can generate unique C<$name> itself if not given.
All frames are deleted when a lambda is stopped.

Example:

    my $counter = 0;
    context lambda { $counter += 1 };
    tail {
        return if 12 == shift;
    	my $frame = restartable;
        context lambda { $counter += 10 };
	tail {
    	   again($frame);
	}
    }

C<restartable> records the current content on the lambda, and C<again> switches it back
so that C<again> call goes to the first C<tail> instead of the second. 

=item delete_frame($frame)

Deletes existing saved frame. Can be used to clean up eventual circular references
(see below).

=item get_frame, set_frame(@frame), swap_frame(@frame)

A lower level frame accessors that save and restore all contexts.  Do not use
directly because it can easily used to inadvertedly create circular references,
where C<@frame> points to a callback while the callback via the closure
mechanisms holds a reference to the C<@frame> variable (Thanks to Ben Tilly for
bringing up the issue).

=back

=head2 Stream IO

The whole point of this module is to help building protocols of arbitrary
complexity in a clear, consequent programming style. Consider how perl's
low-level C<sysread> and C<syswrite> relate to its higher-level C<readline>,
where the latter not only does the buffering, but also recognizes C<$/> as
input record separator.  The section above described lower-level lambda I/O
conditions, that are only useful for C<sysread> and C<syswrite>. This section
tells about higher-level lambdas that relate to these low-level ones, as the
aforementioned C<readline> relates to C<sysread>.

All functions in this section return the lambda, that does the actual work.
Not unlike as a class constructor returns a newly created class instance, these
functions return newly created lambdas. Such functions will be further referred
as lambda constructors, or simply I<constructors>. Therefore, constructors are
documented here as having two inputs and one output, as for example a function
C<sysreader> is a function that takes 0 parameters, always returns a new
lambda, and this lambda, in turn, takes four parameters and returns two. This
constructor will be described as

    # sysreader() :: ($fh,$$buf,$length,$deadline) -> ($result,$error)

Since all stream I/O lambdas return same set of scalars, the return type
will be further on referred as C<ioresult>:

    # ioresult    :: ($result, $error)
    # sysreader() :: ($fh,$$buf,$length,$deadline) -> ioresult

C<ioresult>'s first scalar is defined on success, and is not otherwise.  In the
latter case, the second scalar contains the error, usually either C<$!> or
C<'timeout'> (if C<$deadline> was set).

Before describing the actual functions, consider the code that may benefit from
using them.  Let's take a lambda that needs to implement a very simple HTTP/0.9
request:

   lambda {
       my $handle = shift;
       my $buf = '';
       context getline, $handle, \$buf;
   tail {
       my $req = shift;
       die "bad request" unless $req =~ m[GET (.*)$]i;
       do_request($handle, $1);
   }}

C<getline> reads from C<$handle> to C<$buf>, and wakes up when a new line
is there. However, what if we need, for example, HTTPS instead of HTTP, where
reading from a socket may involve some writing, and of course some waiting?
Then the first default parameter to getline has to be replaced. By default, 

   context getline, $handle, \$buf;

is the same as 

   my $reader = sysreader;	  
   context getline($reader), $handle, \$buf;

where C<sysreader> creates a lambda C<$reader>, that given C<$handle>, awaits
when it becomes readable, and reads from it. C<getline>, in turn, repeatedly
calls C<$reader>, until the whole line is read.

Thus, we call 

   context getline(https_reader), $handle, \$buf;

instead, that should conform to sysreader signature:

   sub https_reader
   {
       lambda {
           my ( $fh, $buf, $length, $deadline) = @_;
	   # read from SSL socket
	   return $error ? (undef, $error) : $data;
       }
   }

I'm not showing the actual implementation of a HTTPS reader (if you're curious,
look at L<IO::Lambda::HTTP::HTTPS> ), but the idea is that inside that reader,
it is perfectly fine to do any number of read and write operations, and wait
for their completion too, as long as the upper-level lambda will sooner or
later gets the data.  C<getline> (or, rather, C<readbuf> that C<getline> is
based on) won't care about internal states of the reader. 

Check out F<t/06_stream.t> that emulates reading and writing implemented 
in this fashion.

These functions are imported with 
  
   use IO::Lambda qw(:stream);

=over

=item sysreader() :: ($fh, $$buf, $length, $deadline) -> ioresult

Creates a lambda that accepts all the parameters used by C<sysread> (except
C<$offset> though), plus C<$deadline>. The lambda tries to read C<$length>
bytes from C<$fh> into C<$buf>, when C<$fh> becomes available for reading. If
C<$deadline> expires, fails with C<'timeout'> error. On successful read,
returns number of bytes read, or C<$!> otherwise.

=item syswriter() :: ($fh, $$buf, $length, $offset, $deadline) -> ioresult

Creates a lambda that accepts all the parameters used by C<syswrite> plus
C<$deadline>. The lambda tries to write C<$length> bytes to C<$fh> from C<$buf>
from C<$offset>, when C<$fh> becomes available for writing. If C<$deadline>
expires, fails with C<'timeout'> error. On successful write, returns number of
bytes written, or C<$!> otherwise.

=item readbuf($reader = sysreader()) :: ($fh, $$buf, $cond, $deadline) -> ioresult

Creates a lambda that is able to perform buffered reads from C<$fh>, either
using custom lambda C<reader>, or using one newly generated by C<sysreader>.
The lambda, when called, reads continually from C<$fh> into C<$buf>, and
either fails on timeout, I/O error, or end of file, or succeeds if C<$cond>
condition matches.

The condition C<$cond> is a "smart match" of sorts, and can be one of:

=over

=item integer

The lambda will succeed when C<$buf> is exactly C<$cond> bytes long.

=item regexp

The lambda will succeed when C<$cond> matches the content of C<$buf>.
Note that C<readbuf> saves and restores value of C<pos($$buf)>, so use of
C<\G> is encouraged here.

=item coderef :: ($buf -> BOOL)

The lambda succeeds if coderef called with C<$buf> returns true value.

=item undef

The lambda will succeed on end of file. Note that for all other conditions end
of file is reported as an error, with literal C<"eof"> string.

=back

=item writebuf($writer) :: ($fh, $$buf, $length, $offset, $deadline) -> ioresult

Creates a lambda that is able to perform buffered writes to C<$fh>, either
using custom lambda C<writer>, or using one generated by C<syswriter>.
That writer lambda, in turn, writes continually C<$buf> (from C<$offset>,
C<$length> bytes) and either fails on timeout or I/O error, or succeeds when
C<$length> bytes are written successfully.

If C<$length> is undefined, buffer is continuously checked if it
got new data. This feature can be used to implement concurrent writes.

=item getline($reader) :: ($fh, $$buf, $deadline) -> ioresult

Same as C<readbuf>, but succeeds when a string of bytes ended by a newline
is read.

=back

=head2 Higher-order functions

Functions described in this section justify the I<lambda> in C<IO::Lambda>.
Named deliberately after the classic function names, they provide a similar
interface.

These function are imported with 
  
   use IO::Lambda qw(:func);

=over

=item mapcar($lambda) :: @p -> @r

Given a C<$lambda>, creates another lambda, that accepts array C<@p>, and
sequentially executes C<$lambda> with each parameter from the array.  The
lambda returns results collected from the executed lambdas.

   print mapcar( lambda { 1 + shift })-> wait(1..5);
   23456

C<mapcar> can be used for organizing simple loops:

   mapcar(curry { sendmail(shift) })-> wait(@email_addresses);

=item filter($lambda) :: @p -> @r

Given a C<$lambda>, creates another lambda, that accepts array C<@p>, and
sequentially executes C<$lambda> with each parameter from the array.  Depending
on the result of the execution, parameters are either returned, or not returned
back to the caller. 

   print filter(lambda { shift() % 2 })-> wait(1..5);
   135

=item fold($lambda) :: @b -> @c; $lambda :: ($a,@b) -> @c

Given a C<$lambda>, returns another lambda that accepts array C<@b>, and runs
pairwise its members through C<$lambda>. Results of repeated execution of
C<$lambda> is returned.

   print fold( lambda { $_[0] + $_[1] } )-> wait( 1..4 );
   10

=item curry(@a -> $l) :: @a -> @b

C<curry> accepts a function that returns a lambda, and possible parameters to
it. Returns a new lambda, that will execute the inner lambda, and returns its
result as is.  For example,

   context $lambda, $a, $b, $c;
   tail { ... }

where C<$lambda> accepts three parameters, can be rewritten as

   $m = curry { $lambda, $a, $b };
   context $m, $c;
   tail { ... }

Another example, tie C<readbuf> with a filehandle and buffer:

   my $readbuf = curry { readbuf, $fh, \(my $buf = '') };

=item seq() :: @a -> @b

Creates a new lambda that executes all lambdas passed to it in C<@a>
sequentially, one after another. The lambda returns results collected from the
executed lambdas.

  sub seq { mapcar curry { shift }}
  print seq-> wait( map { my $k = $_; lambda { $k } } 1..5);
  12345

=item par($max = 0) :: @a -> @b

Given a limit C<$max>, returns a new lambda that accepts lambdas in C<@a> to be
executed in parallel, but so that number of lambdas that run simultaneously
never goes higher than the limit.  The lambda returns results collected from
the executed lambdas.

If C<$max> is undefined or 0, behaves similar to a lambda version of C<tails>,
i.e., all of the lambdas are run in parallel.

The code below prints 123, then sleeps, then 456, then sleeps, then 789.

  par(3)-> wait( map {
      my $k = $_;
      lambda {
          context 0.5;
	  timeout { print $k, "\n" }
      }
  } 1..9);

=back

=head2 Object API

This section lists methods of C<IO::Lambda> class. Note that by design all
lambda-style functionality is also available for object-style programming.
Together with the fact that lambda syntax is not exported by default, it thus
leaves a place for possible implementations of user-defined syntax, either
with or without lambdas, on top of the object API, without accessing the
internals.

The object API is mostly targeted to developers that need to connect
third-party asynchronous event libraries with the lambda interface.

=over

=item new($class, $start)

Creates new C<IO::Lambda> object in the passive state. C<$start>
will be called once, after the lambda gets active.

=item watch_io($flags, $handle, $deadline, $callback, $cancel)

Registers an IO event listener that calls C<$callback> either after
C<$handle> satisfies condition of C<$flags> ( a combination of IO_READ,
IO_WRITE, and IO_EXCEPTION bits), or after C<$deadline> time is passed. If
C<$deadline> is undef, watches for the file handle indefinitely.

The callback is called with first parameter as integer set of IO_XXX flags, or
0 if the callback was timed out. Other parameters, as it is the case with the
other callbacks, are passed the result of the last called callback attached to
the same lambda. The result of this callback will then be stored and passed on
to the next callback in the same fashion.

If the event is cancelled with C<cancel_event>, then C<$cancel> callback
is executed. The result of this callback will be stored and passed on,
in the same manner as results and parameters to C<$callback>.

=item watch_timer($deadline, $callback, $cancel)

Registers a timer listener that calls C<$callback> after C<$deadline> time.

=item watch_lambda($lambda, $callback, $cancel)

Registers a listener that calls C<$callback> after C<$lambda>, a C<IO::Lambda>
object is finished. If C<$lambda> is in passive state, it is started first.

=item is_stopped

Reports whether lambda is stopped or not.

=item is_waiting

Reports whether lambda has any registered callbacks left or not.

=item is_passive

Reports if lambda wasn't run yet. Is true when the lambda is in a state
after either C<new> or C<reset> are called.

=item is_active

Reports if lambda was run.

=item reset

Cancels all watchers and switches the lambda to the passive state. 
If there are any lambdas that watch for this object, these will
be called first.

=item autorestart

If set, gives permission to watchers to reset the lambda if it 
becomes stopped. C<tail> does that when needed, other watchers
are allowed to do that too. Is set by default.

=item peek

At any given time, returns stored data that are either passed
in by C<call> if the lambda is in the passive state, or stored result
of execution of the latest callback.

=item start

Starts a passive lambda. Can be used for effective restart of the whole lambda;
the only requirement is that the lambda should have no pending events.

=item call @args

Stores C<@args> internally, to be passed on to the first callback. Only
works in passive state, croaks otherwise. If called multiple times,
arguments from the previous calls are overwritten.

=item terminate @args

Cancels all watchers and resets lambda to the stopped state.  If there are any
lambdas that watch for this object, these will be notified first. C<@args> will
be stored and available for later calls by C<peek>.

=item destroy

Cancels all watchers and resets lambda to the stopped state. Does the same to
all lambdas the caller lambda watches after, recursively. Useful where
explicit, long-lived lambdas shouldn't be subject to the global destruction,
which kills objects in random order; C<destroy> kills them in some order, at
least.

=item wait @args

Waits for the caller lambda to finish, returns the result of C<peek>.
If the object was in passive state, calls C<call(@args)>, otherwise
C<@args> are not used.

=item wait_for_all @lambdas

Waits for caller lambda and C<@lambdas> to finish. Returns collection of
C<peek> results for all objects. The results are unordered.

=item wait_for_any @lambdas

Waits for at least one lambda from the list of caller lambda and C<@lambdas> to
finish. Returns list of finished objects.

=item yield $nonblocking = 0

Runs one round of dispatching events. Returns 1 if there are more events
in internal queues, 0 otherwise. If C<$NONBLOCKING> is set, exits as soon
as possible, otherwise waits for events; this feature can be used for
organizing event loops without C<wait/run> calls.

=item run

Enters the event loop and doesn't exit until there are no registered events.
Can be also called as package method.

=item bind $cancel, @args

Creates an event record that contains the lambda and C<@args>, and returns it.
The lambda won't finish until this event is returned with C<resolve>.
C<$cancel> is an optional callback that will be called when the event is
cancelled; the callback is passed two parameters, the lambda and the cancelled
event record.

C<bind> can be called several times on a single lambda; each event requires
individual C<resolve>.

=item resolve $event

Removes C<$event> from the internal waiting list. If a lambda has no more
events to wait, notifies eventual lambdas that wait to the objects, and
then stops.

Note that C<resolve> doesn't provide any means to call associated
callbacks, which is intentional.

=item intercept $condition [ $state = '*' ] $coderef

Installs a C<$coderef> as an overriding hook for a condition callback, where
condition is C<tail>, C<readable>, C<writable>, etc.  Whenever a condition callback
is being called, the C<$coderef> hook will be called instead, that should be able to
analyze the call, and allow or deny it the further processing. 

C<$state>, if omitted, is equivalent to C<'*'>, that means that checks on
lambda state are omitted too. Setting C<$state> to C<undef> is allowed though,
and will match when the lambda state is also undefined (which it is by
default).

There can exist more than one C<intercept> handlers, stacked on top of each
other. If C<$coderef> is C<undef>, the last registered hook is removed.

Example:

    my $q = lambda { ... tail { ... }};
    $q-> intercept( tail => sub {
	if ( stars are aligned right) {
	    # pass
            return this-> super(@_);
	} else {
	    return 'not right';
	}
    });

See also C<state>, C<super>, and C<override>.

=item override $condition [ $state = '*' ] $coderef

Installs a C<$coderef> as an overriding hook for a condition - C<tail>, C<readable>,
C<writable>, etc, possibly with a named state.  Whenever a lambda calls one of
these condition, the C<$coderef> hook will be called instead, that should be
able to analyze the call, and allow or deny it the further processing. 

C<$state>, if omitted, is equivalent to C<'*'>, that means that checks on lambda 
state are omitted too. Setting C<$state> to C<undef> is allowed though, and will
match when the lambda state is also undefined (which it is by default).

There can exist more than one C<override> handlers, stacked on top of each
other. If C<$coderef> is C<undef>, the last registered hook is removed.

Example:

    my $q = lambda { ... tail { ... }};
    $q-> override( tail => sub {
	if ( stars are aligned right) {
	    # pass
            this-> super;
	} else {
	    # deny and rewrite result
	    return tail { 'not right' }
	}
    });

See also C<state>, C<super>, and C<intercept>.

=item super

Analogous to Perl's C<SUPER>, but on the condition level, this method is
designed to be called from overridden conditions to call the original condition
or callback.

There is a slight difference in the call syntax, depending on whether it is
being called from inside an C<override> or C<intercept> callback. The
C<intercept>'ed callback will call the previous callback right away, and may
call it with parameters directly. The C<override> callback will only call the
condition registration routine itself, not the callback, and therefore is
called without parameters. See L<intercept> and L<override> for examples of
use.

=item state $state

A helper function for explicit naming of condition calls. The function stores
the C<$state> string on the current lambda; this string can be used in calls
to C<intercept> and C<override> to identify a particular condition or a callback.

The recommended use of the method is when a lambda contains more than one
condition of a certain type; for example the code

   tail {
   tail {
      ...
   }}

is therefore better to be written as

   state A => tail {
   state B => tail {
      ...
   }}

=back

=head2 Exceptions and backtrace

In addition to the normal call stack as reported by the C<caller> builtin,
it can be useful also to access execution information of the thread of
events, when a lambda waits for another, which in turn waits for another,
etc. The following functions deal with backtrace information and
exceptions, that propagate through thread of events.

=over

=item catch $coderef, $event

Registers $coderef on $event, that is called when $event is aborted
via either C<cancel_event>, C<cancel_all_event>, or C<terminate>:

   my $resource = acquire;
   context lambda { .. $resource .. };
   catch {
      $resource-> free;
   } tail {
      $resource-> free;
   }

C<catch> must be invoked after a condition, but in the syntax above that means
that C<catch> should lexically come before it. If undesirable, use explicit
event reference:

   my $event = tail { ... };
   catch   { ... }, $event;

=item autocatch $event

Prefixes a condition, so that it is called even if cancelled.
However, immediately after the call the exception is rethrown.
Can be used in the following fashion:

    context lambda ...;
    autocatch tail {
        print "aborted\n" if this-> is_cancelling;
        .. finalize ...
    };

=item is_cancelling

Returns true if running within a C<catch> block.

=item call_again(@param)

To be called only from within a C<catch> block. Calls the normal
callback that would be called if the event wouldn't be cancelled.
C<@param> is passed to the callback.

=item throw(@error)

Terminates the current lambda, then propagates C<@error> to the immediate
caller lambdas. They will have a chance to catch the exception with C<catch>
later, and re-throw by calling C<throw> again. The default action is to
propagate the exception further.

When there are no caller lambdas, a C<sigthrow> callback is called ( analog:
die outside eval calls $SIG{__DIE__} ).

=item sigthrow($callback :: ($lambda, @error))

Retrieves and sets a callback that is invoked when C<throw> is called
on lambda that no lambdas wait for. By default, is empty. When invoked,
is passed the lambda, and parameters passed to C<throw>.

=item callers

Returns event records that watch for the lambda.

=item callees

Returns event records that corresponds to the lambdas this lambda watches.

=item backtrace

Returns a C<IO::Lambda::Backtrace> object that represents thread of events
which leads to the current lambda. See L<IO::Lambda::Backtrace> for more.

=back

=head1 MISCELLANEOUS

=head2 Included modules

=over

=item *

L<IO::Lambda::Backtrace> - debug chains of events

=item *

L<IO::Lambda::Signal> - POSIX signals.

=item *

L<IO::Lambda::Socket> - lambda versions of C<connect>, C<accept> etc.

=item *

L<IO::Lambda::HTTP> - implementation of HTTP and HTTPS protocols.  HTTPS
requires L<IO::Socket::SSL>, NTLM/Negotiate authentication requires
L<Authen::NTLM> modules (not marked as dependencies).

=item *

L<IO::Lambda::DNS> - asynchronous domain name resolver.

=item *

L<IO::Lambda::SNMP> - SNMP requests lambda style. Requires L<SNMP>.

=item * 

L<IO::Lambda::Thread> - run blocking code executed in another thread.
Requires perl version greater than 5.8.0, preferably 5.10.0,
built with threads.

=item *

L<IO::Lambda::Fork> - run blocking code executed in another
process context. Doesn't work on win32 for obvious reasons.

=item *

L<IO::Lambda::Message> - base class for message queues over existing
file handles.

=item *

L<IO::Lambda::DBI> - asynchronous DBI

=item *

L<IO::Lambda::Poll> - generic polling wrapper

=item *

L<IO::Lambda::Flock> - flock(2) wrapper

=item *

L<IO::Lambda::Mutex> - wait for a shared resource

=back

=head2 Debugging

Various sub-modules can be controlled with the single environment variable,
C<IO_LAMBDA_DEBUG>, which is treated as a comma-separated list of modules.
For example,

      env IO_LAMBDA_DEBUG=io=2,http perl script.pl

displays I/O debug messages from C<IO::Lambda> (with extra verbosity) and from
C<IO::Lambda::HTTP>. C<IO::Lambda> responds for the following keys:

=over

=item io

Prints debugging information about file and timeout asynchronous events.

=item lambda

Print debugging information about event flow of lambda objects,
where one object waits for another, lambda being cancelled, finished, etc.

=item caller

Increase verbosity of I<lambda> by storing information about which line
invoked object creation and subscription. See L<IO::Lambda::Backtrace>
for more.

=item die 

If set, fatal errors dump the stack trace.

=item loop=MODULE

Sets loop module, one of: Select, AnyEvent, Prima, POE.

=back

Keys recognized for the other modules:
I<select,dbi,http,https,signal,message,thread,fork,poll,flock>.

=head2 Online information

Project homepage: L<http://iolambda.karasik.eu.org/>

Mailing list: I<io-lambda-general at lists.sourceforge.net>, thanks to sourceforge.
Subscribe by visiting L<https://lists.sourceforge.net/lists/listinfo/io-lambda-general>.

=head2 Benchmarks

=over

=item *

A single-process TCP client and server; server echoes back everything is sent by
the client. 500 connections sequentially created, instructed to send a single
line to the server, and destroyed.

                         2.4GHz x86-64 linux 1.2GHz win32
  Lambda/select              0.697            7.468
  Lambda/select, optimized   0.257            5.273
  Lambda/AnyEvent            0.648            8.175
  Lambda/AnyEvent, optimized                  7.087
  Raw sockets using select   0.149            4.859
  POE/select, components     1.185           12.306
  POE/select, raw sockets    0.382            6.233
  POE/select, optimized      0.770            7.510

See benchmarking code in F<eg/bench>.

=back

=head2 Apologetics

There are many async libraries readily available from CPAN. C<IO::Lambda> is
yet another one. How is it different from the existing tools? Why use it?  To
answer these questions, I need to show the evolution of async libraries, to
explain how they grew from simple tools to complex frameworks.

First, all async libraries are based on OS-level syscalls, like C<select>,
C<poll>, C<epoll>, C<kqueue>, and C<Win32::WaitForMultipleObjects>. The first
layer provides access to exactly these facilities: there are C<IO::Select>,
C<IO::Epoll>, C<IO::Kqueue> etc. I won't go deeper into describing pros and
cons for programming on this level, this should be obvious.

Perl modules of the next abstraction layer are often characterised by
portability and event loops. While the modules of the first layer are seldom
portable, and have no event loops, the second layer modules strive to be
OS-independent, and use callbacks to ease the otherwise convoluted ways async
I/O would be programmed. These modules mostly populate the "asynchronous
input-output programming frameworks" niche in the perl world. The examples are
many: C<IO::Events>, C<EV>, C<AnyEvent>, C<IO::NonBlocking>, C<IO::Multiplex>,
to name a few. 

Finally, there's the third layer of complexity, which, before C<IO::Lambda>,
had a single representative: C<POE> (now, to the best of my knowledge,
C<IO::Async> also partially falls in this category). Modules of the third layer
are based on concepts from the second, but introduce a powerful tool to help
the programming of complex protocols, something that isn't available in the
second layer modules: finite state machines (FSMs). The FSMs reduce programming
complexity, for example, of intricate network protocols, that are best modelled
as a set of states in a logical circuit. Also, the third layer modules are
agnostic of the event loop module: the programmer is (almost) free to choose
the event loop backend, such as native C<select>, C<Gtk>, C<EV>, C<Prima>, or
C<AnyEvent>, depending on the nature of the task.

C<IO::Lambda> allows the programmer to build protocols of arbitrary complexity,
and is also based on event loops, callbacks, and is portable. It differs from
C<POE> in the way the FSMs are declared. Where C<POE> requires an explicit
switch from one state to another, using f.ex. C<post> or C<yield> commands,
C<IO::Lambda> incorporates the switching directly into the program syntax.
Consider C<POE> code:

   POE::Session-> create(
       inline_states => {
           state1 => sub { 
	      print "state1\n";
	      $_[ KERNEL]-> yield("state2");
	   },
	   state2 => sub {
	      print "state2\n";
	   },
   });

and the corresponding C<IO::Lambda> code (I<state1> and I<state2> are I<conditions>,
they need to be declared separately):

    lambda {
       state1 {
	  print "state1\n";
       state2 {
	  print "state2\n";
       }}
    }

In C<IO::Lambda>, the programming style is (deliberately) not much different
from the declarative

    print "state1\n";
    print "state2\n";

as much as the nature of asynchronous programming allows that.

To sum up, the intended use of C<IO::Lambda> is for areas where simple
callback-based libraries require lots of additional work, and where state machines
are beneficial. Complex protocols like HTTP, parallel execution of several
tasks, strict control of task and protocol hierarchy - this is the domain where
C<IO::Lambda> works best.


=head1 LICENSE AND COPYRIGHT

This work is partially sponsored by capmon ApS.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

I wish to thank those who helped me:

Ben Tilly for providing thorough comments to the code in the synopsis, bringing
up various important issues, valuable discussions, for his patience and
dedicated collaboration.

David A. Golden for discussions about names, and his propositions to rename
some terms into more appropriate, such as "read" to "readable", and "predicate"
to "condition". Rocco Caputo for optimizing the POE benchmark script. Randal
L. Schwartz, Brock Wilcox, and zby@perlmonks helped me to understand how the
documentation for the module could be made better.

All the good people on perlmonks.org and perl conferences, who invested their
time into understanding the module.

=cut
