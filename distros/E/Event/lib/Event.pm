use strict;

BEGIN {  # do the right thing for threads?
    eval { require attrs; } or do {
	$INC{'attrs.pm'} = "";
	*attrs::import = sub {};
    }
}

package Event;
require 5.008;
use base 'Exporter';
use Carp;
eval { require Carp::Heavy; };  # work around perl_call_pv bug XXX
our $API;
our $VERSION = '1.27';

# If we inherit DynaLoader then we inherit AutoLoader; Bletch!
require DynaLoader;

# DynaLoader calls dl_load_flags as a static method.
*dl_load_flags = DynaLoader->can('dl_load_flags');
(defined(&bootstrap)? \&bootstrap : \&DynaLoader::bootstrap)->
    (__PACKAGE__, $VERSION);

our $DebugLevel = 0;
our $Eval = 0;		# avoid because c_callback is exempt
our $DIED = \&default_exception_handler;

our @EXPORT_OK = qw(time all_events all_watchers all_running all_queued all_idle
		one_event sweep loop unloop unloop_all sleep queue
		queue_pending
		QUEUES PRIO_NORMAL PRIO_HIGH NO_TIME_HIRES);

sub import {
  my $pkg = shift;
  our $NO_TIME_HIRES;
  my @sym;
  for my $sym (@_) {
    if ($sym eq 'NO_TIME_HIRES') {
      $NO_TIME_HIRES = 1;
    } else {
      push @sym, $sym;
    }
  }

  if (!$NO_TIME_HIRES) {
    eval { require Time::HiRes; };
    if ($@ =~ /^Can\'t locate Time/) {
      # OK, just continue
    } elsif ($@) {
      die if $@;
    } else {
      cache_time_api();  # hook in high precision time
    }
  }

  $pkg->export_to_level(1, undef, @sym);
}

# broadcast_adjust for Time::Warp? XXX

sub _load_watcher {
    my $sub = shift;
    eval { require "Event/$sub.pm" };
    die if $@;
    croak "Event/$sub.pm did not define Event::$sub\::new"
	unless defined &$sub;
    1;
}

sub AUTOLOAD {
    my $sub = ($Event::AUTOLOAD =~ /(\w+)$/)[0];
    _load_watcher($sub) or croak $@ . ', Undefined subroutine &' . $sub;
    carp "Autoloading with Event->$sub(...) is deprecated;
\tplease 'use Event::type qw($sub);' explicitly";
    goto &$sub;
}

sub default_exception_handler {
    my ($run,$err) = @_;
    my $desc = '?';
    my $w;
    if ($run and ($w = $run->w)) {
	$desc = "`".$w->desc."'";
    }
    my $m = "Event: trapped error in $desc: $err";
    $m .= "\n" if $m !~ m/\n$/;
    warn $m;
    #Carp::cluck "Event: fatal error trapped in '$desc'";
}

sub verbose_exception_handler { #AUTOLOAD XXX
    my ($e,$err) = @_;

    my $m = "Event: trapped error: $err";
    $m .= "\n" if $m !~ m/\n$/;
    return warn $m if !$e;

    my $w = $e->w;
    $m .= "  in $w --\n";

    for my $k ($w->attributes) {
	$m .= sprintf "%18s: ", $k;
	eval {
	    my $v = $w->$k();
	    if (!defined $v) {
		$m .= '<undef>';
	    } elsif ($v =~ /^-?\d+(\.\d+)?$/) {
		$m .= $v;
	    } else {
		$m .= "'$v'";
	    }
	};
	if ($@) { $m .= "[$@]"; $@=''; }
	$m .= "\n";
    }
    warn $m;
}

sub sweep {
    my $prio = @_ ? shift : QUEUES();
    queue_pending();
    my $errsv = '';
    while (1) {
	eval { $@ = $errsv; _empty_queue($prio) };
	$errsv = $@;
	if ($@) {
#	    if ($Event::DebugLevel >= 2) {
#		my $e = all_running();
#		warn "Event: '$e->{desc}' died with: $@";
#	    }
	    next
	}
	last;
    }
}

use vars qw($Result $TopResult);

my $loop_timer;
sub loop {
    use integer;
    if (@_) {
	my $how_long = shift;
	if (!$loop_timer) {
	    $loop_timer = Event->timer(desc => "Event::loop timeout",
				       after => $how_long,
				       cb => sub { unloop($how_long) },
				       parked=>1);
	    $loop_timer->prio(PRIO_HIGH());
	} else {
	    $loop_timer->at(Event::time() + $how_long),
	}
	$loop_timer->start;
    }
    $TopResult = undef;    # allow re-entry of loop after unloop_all
    local $Result = undef;
    _incr_looplevel();
    my $errsv = '';
    while (1) {
	# like G_EVAL | G_KEEPERR
	eval { $@ = $errsv; _loop() };
	$errsv = $@;
	if ($@) {
	    warn "Event::loop caught: $@"
		if $Event::DebugLevel >= 4;
	    next
	}
	last;
    }
    _decr_looplevel();
    $loop_timer->stop if $loop_timer;
    my $r = $Result;
    $r = $TopResult if !defined $r;
    warn "Event: unloop(".(defined $r?$r:'<undef>').")\n"
	if $Event::DebugLevel >= 3;
    $r
}

sub add_hooks {
    shift if @_ & 1; #?
    while (@_) {
	my $k = shift;
	my $v = shift;
	croak "$v must be CODE" if ref $v ne 'CODE';
	_add_hook($k, $v);
    }
}

END { $_->cancel for all_watchers() } # buggy? XXX

package Event::Event::Io;
use vars qw(@ISA);
@ISA = 'Event::Event';

package Event::Event::Dataful;
use vars qw(@ISA);
@ISA = 'Event::Event';

package Event;
require Event::Watcher;
_load_watcher($_) for qw(idle io signal timer var);

# Provide hints to Inline.pm for usage:
# use Inline with => 'Event';
sub Inline {
    my ($class, $language) = @_;
    return if $language ne 'C'; # Inline gives good error message
    require Event::MakeMaker;
    my $path = $Event::MakeMaker::installsitearch;
    require Config;
    my $so = $Config::Config{so};
    return {
	INC => "-I $path/Event",
	TYPEMAPS => "$path/Event/typemap",
	MYEXTLIB => "$path/auto/Event/Event.$so",
	AUTO_INCLUDE => '#include "EventAPI.h"',
	BOOT => 'I_EVENT_API("Inline");',
    };
}

1;
