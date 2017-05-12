## -*- Mode: CPerl -*-
## File: DiaColloDB::Client.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, timer

package DiaColloDB::Timer;
use Time::HiRes qw(gettimeofday tv_interval);
use DiaColloDB::Utils qw(:time);
use strict;


##==============================================================================
## Globals & Constants

our @ISA = qw();

##==============================================================================
## Constructors etc.

## $timer = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    started => $t0,      ##-- time last operation started
##    elapsed => $elapsed, ##-- elapsed time (after stop())
##   )
sub new {
  my $that = shift;
  return bless({
		started=>undef,
		elapsed=>0,
		@_
	       }, ref($that)||$that);
}

##==============================================================================
## Timing

## $timer = CLASS_OR_OBJECT->start()
##  + (re-)starts timer
sub start {
  my $timer = shift;
  $timer = $timer->new() if (!ref($timer));
  $timer->{started} = [gettimeofday];
  return $timer;
}

## $timer = $timer->stop()
##  + stops timer and adds current interval to {elapsed}
sub stop {
  my $timer = shift;
  return $timer if (!defined($timer->{started}));
  $timer->{elapsed} = $timer->elapsed();
  $timer->{started} = undef;
  return $timer;
}

## $timer = $timer->reset()
##  + stops and re-sets timer
sub reset {
  my $timer = shift;
  $timer->{started} = undef;
  $timer->{elapsed} = 0;
  return $timer;
}

## $elapsed = $timer->elapsed()
##  + get total elapsed time for this timer
sub elapsed {
  my $timer = shift;
  return $timer->{elapsed} + (defined($timer->{started}) ? tv_interval($timer->{started},[gettimeofday]) : 0);
}


## $hms       = $timer->hms($sfmt?)
## ($h,$m,$s) = $timer->hms($sfmt?)
##  + parses and optionally formats elapsed time as HH:MM:SS.SSS
sub hms {
  return DiaColloDB::Utils::s2hms($_[0]->elapsed,@_[1..$#_]);
}

## $timestr = $timer->timestr($sfmt?)
##  + parses and formats elapsed time as Hh?Mm?Ss
sub timestr {
  return DiaColloDB::Utils::s2timestr($_[0]->elapsed,@_[1..$#_]);
}

##==============================================================================
## Footer
1;

__END__




