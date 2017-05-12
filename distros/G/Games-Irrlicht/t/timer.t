#!/usr/bin/perl -w

use Test::More tests => 45;
use strict;
  
my $c = 'Games::Irrlicht::Timer';

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Irrlicht::Timer');
  }

can_ok ($c, qw/ 
  count due next_shot
  new _init activate is_active deactivate id
  fire is_due
  /);

my $fired = 0;

sub fire
  {
  my ($self,$timer,$timer_id) = @_;

  $fired++;
  }

my $de = 0; sub _deactivated_thing { $de ++; }
my $ac = 0; sub _activated_thing { $ac ++; }

##############################################################################
# timer with limited count

my $timer = $c->new ('main', 100, 2, 200, 0, 128, \&fire, ); 

is (ref($timer), $c, 'timer new worked');
is ($timer->id(), 1, 'timer id is 1');
is ($timer->count(), 2, 'timer count is 2');
is ($timer->next_shot(), 228, 'timer fires at 228');
is ($timer->due(227,1), 0, 'timer is not due at 227');
is ($timer->due(229,1), 1, 'timer was due at 229');
is ($fired, 1, 'timer fired');
is ($timer->count(), 1, 'one less');
is ($timer->next_shot(), 428, 'next shot at 228 + 200');
is ($timer->due(429,1), 1, 'timer was due at 429');
is ($fired, 2, 'timer fired again');
is ($timer->count(), 0, 'one less');
is ($timer->next_shot(), 628, 'never');
is ($timer->due(629,1), 0, 'timer is not due');
is ($fired, 2, "timer didn't fire");

##############################################################################
# timer with unlimited count

$timer = $c->new ('main', 0, -1, 200, 0, 128, \&fire, ); 

is (ref($timer), $c, 'timer new worked');
is ($fired, 3, "timer already fired once");
is ($timer->id(), 2, 'timer id is unqiue and 2');
is ($timer->count(), -1, 'timer count is -1');
is ($timer->next_shot(), 328, 'timer fires next at 128+200');
is ($timer->due(327,1), 0, 'timer is not due at 227');
is ($timer->due(329,1), 1, 'timer was due at 229');
is ($fired, 4, 'timer fired again');
is ($timer->count(), -1, 'count unchanged');

sub fire2
  {
  my ($self, $timer, $overshot, @args) = @_;

  is ($overshot, 0, 'overshot is 0');
  is (scalar @args, 2, 'got 2 additional arguments');
  is ($args[0], 119, 'got first right');
  is ($args[1], 117, 'got second right');
  }

# timer with additional arguments
$timer = $c->new 
  ('main', 0, 1, 200, 0, 128, \&fire2, 119, 117); 
is (ref($timer), $c, 'timer new worked');

# timer with negative target time (if clock goes backwards)

$timer =
  $c->new (
   'main', -1000, 1, 200, 0, 2000, \&fire2, 119, 117); 
is (ref($timer), $c, 'timer new worked');
is ($timer->next_shot(), 1000, 'timer would fire in t-1000');

##############################################################################
# timer with random delay
srand(3);					# definite rand for testing
my @rand = rand(400);
push @rand, rand(400);
srand(3);					# reset for testing

# test rand() in initial time
$timer =
  $c->new ( 
   'main', 1000, 1, 2000, 400, 0, \&fire); 
is (ref($timer), $c, 'timer new worked');
is ($timer->next_shot(), int(1000 + $rand[0] - 200), 'timer would fire ok');
# test rand() in delay time
is ($timer->due(2000,1), 1, 'ok due');
is ($timer->next_shot(), 
    int(1000 + $rand[0] - 200) + int(2000 + $rand[1] - 200), 'delay is fine');

srand(3);					# definite rand for testing
# test deactivated timers
$timer =
  $c->new ('main', 1000, 1, 2000, 400, 0, \&fire); 
is (ref($timer), $c, 'timer new worked');
is ($timer->next_shot(), int(1000 + $rand[0] - 200), 'timer would fire ok');
is ($timer->count(), 1, 'timer fires once');
$timer->deactivate();
is ($timer->next_shot(), int(1000 + $rand[0] - 200), 'timer would fire ok');
is ($timer->count(), 1, 'timer still fires once');
is ($timer->is_active(), 0, 'timer not active');
is ($timer->due(2000,1), 0, 'ok is not due');

# test due with time_warp beeing zero
$timer->activate();
is ($timer->due(2000,0), 0, 'ok is not due');

