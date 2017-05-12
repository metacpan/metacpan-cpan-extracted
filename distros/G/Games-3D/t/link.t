#!/usr/bin/perl -w

use Test::More tests => 52;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  chdir 't' if -d 't';
  use_ok ('Games::3D::Link');
  }

can_ok ('Games::3D::Link', qw/ 
  new _init activate deactivate is_active id name
  state output signal add_input add_output
  insert remove container
  link
  and_gate
  delay count
  once invert fixed_output
  /);
    
use Games::3D::Signal qw/
  SIG_ON SIG_OFF STATE_OFF STATE_ON SIG_ACTIVATE SIG_DEACTIVATE
  SIG_FLIP
 /;

# create link
my $link = Games::3D::Link->new ( );

is (ref($link), 'Games::3D::Link', 'new worked');
is ($link->id(), 1, 'id is 1');

is ($link->and_gate(), 0, 'OR gate');
is ($link->and_gate(1), 1, 'AND gate');

is ($link->is_active(), 1, 'is active');
is ($link->deactivate(), 0, 'is deactive');
is ($link->deactivate(), 0, 'is still deactive');

is ($link->is_active(), 0, 'is no longer active');
is ($link->activate(), 1, 'is active again');

is ($link->activate(), 1, 'is stil active');

is ($link->name(), 'Link #1', "knows it's name");

is (join(" ",$link->delay()), '0 2000 0', "0 s delay, 2 seconds, 0 rand");
is ($link->count(), 1, "once");
is ($link->count(-1), -1, "infinitely");
is ($link->count(2), 2, "twice");
is ($link->count(1), 1, "once");
is ($link->repeat(), 2000, "2 seconds");

is ($link->once(), 0, 'not an one-shot link');
is ($link->invert(), 0, 'not an inverted link');
is (!defined $link->fixed_output(), 1, 'no fixed output');

##############################################################################
# create two thingies and link them together

my $t1 = Games::3D::Thingy->new( );
my $t2 = Games::3D::Thingy->new( );

$link->link($t1,$t2);

is (keys %{$t1->{outputs}}, 1, 'one listener');
is (ref($t1->{outputs}->{1}), 'Games::3D::Link', 'listener on t1 ok');
is (ref($link->{outputs}->{3}), 'Games::3D::Thingy', 'listener on link ok');

is ($t2->state(), STATE_OFF, 't2 is off');

# sending as object
$t1->output($t1,SIG_ON);
$t2->update(1);
is ($t2->state(), STATE_ON, 't2 is now on');

# sending as id
$t1->output($t1,SIG_OFF);
$t2->update(2);
is ($t2->state(), STATE_OFF, 't2 is now off');

# state change on t1 causes signal to be sent to t2
$t1->state(STATE_ON);
$t1->update(3);
is ($t1->state(), STATE_ON, 't1 is on after state change');
is ($t2->state(), STATE_OFF, 
  't2 is off, since t1 relayed STATE_ON (not SIG_ON!)');

# set to off
$t1->state(STATE_OFF); $t1->update(3);
is ($t1->state(), STATE_OFF, 't1 is off after state change');

# send signal that gets relayed
$t1->signal($t1,SIG_ON);
$t1->update(3);
is ($t1->state(), STATE_ON, 't1 is on after state change');
$t2->update(3);
is ($t2->state(), STATE_ON, 
  't2 is on, since t1 relayed SIG_ON!');

##############################################################################
# create three thingies and link them together with an AND gate

$t1 = Games::3D::Thingy->new( );
$t2 = Games::3D::Thingy->new( );
my $t3 = Games::3D::Thingy->new( );

print "# ",$t1->name(),"\n";
print "# ",$t2->name(),"\n";
print "# ",$t3->name(),"\n";
print "# ",$link->name(),"\n";

$link->unlink();

$link->link($t1,$t3);

is (keys %{$t1->{outputs}}, 1, 'one listener');
is (ref($t1->{outputs}->{$link->id()}), 'Games::3D::Link', 'listener on t1 ok');
is (ref($link->{outputs}->{$t3->id()}), 'Games::3D::Thingy', 'listener on link ok');
is (keys %{$link->{outputs}}, 1, 'one listener on link');
is ($t1->{outputs}->{1}, $link, 'listener on t1 ok');

$link->link($t2,$t3);

is (keys %{$t1->{outputs}}, 1, 'one listener');
is (ref($t1->{outputs}->{1}), 'Games::3D::Link', 'listener on t1 ok');
is (keys %{$t2->{outputs}}, 1, 'one listener');
is (ref($t2->{outputs}->{1}), 'Games::3D::Link', 'listener on t1 ok');
is ($t2->{outputs}->{1}, $link, 'listener on t1 ok');
is (keys %{$link->{outputs}}, 1, 'one listener on link');
is (ref($link->{outputs}->{$t3->id()}), 'Games::3D::Thingy', 'listener on link ok');

$link->and_gate(0);	# OR gate

$t3->state(STATE_OFF);

# inactivate link

$t1->output($t1,SIG_DEACTIVATE);
is ($link->is_active(), 0, 'inactive now');
is ($t3->is_active(), 1, "didn't get releayed");
is ($t3->state(), STATE_OFF, 't3 off (signal not relayed)');

$t1->signal($t1,SIG_FLIP);
is ($t3->state(), STATE_OFF, 't3 is still off (link inactive)');

#############################################################################
# kill thingy and observe SIG_KILLED

$link->activate();
is ($link->is_active(), 1, 'active again');
$link->{fixed_output} = SIG_ON;

# this will send SIG_KILLED, the link will convert this to SIG_ON and t3
# must be ON after that
is ($t3->state(), STATE_OFF, 't3 is still off (link inactive)');
$t1->kill();
$t3->update(4);
is ($t3->state(), STATE_ON, 't3 is now on');

#############################################################################

# needs an app
#$t2->state(STATE_ON);
#
#is (join(" ",$link->delay(0,50,0)), '0 2000 0', "0 s delay, 2 seconds, 0 rand");
#is ($link->count(2), 2, "twice");
#$t1->output($t1,STATE_FLIP);
#sleep(1);
#is ($t2->state(), STATE_ON, 'flipping twice is still on');
#
#is ($link->count(3), 3, "three times");
#$t1->output($t1,STATE_FLIP);
#sleep(1);
#is ($t2->state(), STATE_OFF, 'flipping three times is off');

