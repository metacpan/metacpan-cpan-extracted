
# Signal - define the signal names and constants

package Games::3D::Signal;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use vars qw/@ISA @EXPORT_OK $VERSION/;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/ 
  SIG_ON SIG_UP SIG_OPEN
  SIG_OFF SIG_CLOSE SIG_DOWN
  SIG_FLIP SIG_DIE
  SIG_ACTIVATE SIG_DEACTIVATE

  SIG_KILLED SIG_UNKNOWN

  SIG_LEFT SIG_RIGHT
  STATE_FLIP
  STATE_ON STATE_UP STATE_OPEN
  STATE_OFF STATE_CLOSED STATE_DOWN

  SIG_LEVEL_WON
  SIG_LEVEL_LOST
  invert state_from_signal signal_from_state signal_name

  STATE_0 STATE_1 STATE_2 STATE_3 STATE_4 STATE_5 STATE_6 STATE_7 STATE_8
  STATE_9 STATE_10 STATE_11 STATE_12 STATE_13 STATE_14 STATE_15
  
  SIG_STATE_0 SIG_STATE_1 SIG_STATE_2 SIG_STATE_3 SIG_STATE_4 SIG_STATE_5
  SIG_STATE_6 SIG_STATE_7 SIG_STATE_8
  SIG_STATE_9 SIG_STATE_10 SIG_STATE_11 SIG_STATE_12 SIG_STATE_13 SIG_STATE_14
  SIG_STATE_15

  SIG_NOW_0 SIG_NOW_1 SIG_NOW_2 SIG_NOW_3 SIG_NOW_4 SIG_NOW_5
  SIG_NOW_6 SIG_NOW_7 SIG_NOW_8
  SIG_NOW_9 SIG_NOW_10 SIG_NOW_11 SIG_NOW_12 SIG_NOW_13 SIG_NOW_14
  SIG_NOW_15
  /;

$VERSION = '0.02';

##############################################################################
# constants

# todo: make SIG_ON == SIG_STATE_0 and SIG_OFF == SIG_STATE_1
sub SIG_ON () { 1; }
sub SIG_OPEN () { 1; }
sub SIG_UP () { 1; }
sub SIG_RIGHT () { 1; }

sub SIG_OFF () { -1; }
sub SIG_CLOSE () { -1; }
sub SIG_DOWN () { -1; }
sub SIG_LEFT () { -1; }

sub SIG_FLIP () { 0; }	

# these don't need a state since they are not passed along
sub SIG_ACTIVATE () { 2; }
sub SIG_DEACTIVATE () { -2; }

sub STATE_0 ()  { 0; }
sub STATE_1 ()  { 1; }
sub STATE_2 ()  { 2; }
sub STATE_3 ()  { 3; }
sub STATE_4 ()  { 4; }
sub STATE_5 ()  { 5; }
sub STATE_6 ()  { 6; }
sub STATE_7 ()  { 7; }
sub STATE_8 ()  { 8; }
sub STATE_9 ()  { 9; }
sub STATE_10 () { 10; }
sub STATE_11 () { 11; }
sub STATE_12 () { 12; }
sub STATE_13 () { 13; }
sub STATE_14 () { 14; }
sub STATE_15 () { 15; }

sub SIG_STATE_0 () { 100; }
sub SIG_STATE_1 () { 101; }
sub SIG_STATE_2 () { 102; }
sub SIG_STATE_3 () { 103; }
sub SIG_STATE_4 () { 104; }
sub SIG_STATE_5 () { 105; }
sub SIG_STATE_6 () { 106; }
sub SIG_STATE_7 () { 107; }
sub SIG_STATE_8 () { 108; }
sub SIG_STATE_9 () { 109; }
sub SIG_STATE_10 () { 110; }
sub SIG_STATE_11 () { 111; }
sub SIG_STATE_12 () { 112; }
sub SIG_STATE_13 () { 113; }
sub SIG_STATE_14 () { 114; }
sub SIG_STATE_15 () { 115; }

sub SIG_NOW_0 () { 200; }
sub SIG_NOW_1 () { 201; }
sub SIG_NOW_2 () { 202; }
sub SIG_NOW_3 () { 203; }
sub SIG_NOW_4 () { 204; }
sub SIG_NOW_5 () { 205; }
sub SIG_NOW_6 () { 206; }
sub SIG_NOW_7 () { 207; }
sub SIG_NOW_8 () { 208; }
sub SIG_NOW_9 () { 209; }
sub SIG_NOW_10 () { 210; }
sub SIG_NOW_11 () { 211; }
sub SIG_NOW_12 () { 212; }
sub SIG_NOW_13 () { 213; }
sub SIG_NOW_14 () { 214; }
sub SIG_NOW_15 () { 215; }

sub SIG_DIE () { 1000; }
sub SIG_KILLED () { 1001; }

sub STATE_ON () { 1; }
sub STATE_OPEN () { 1; }
sub STATE_UP () { 1; }
sub STATE_RIGHT () { 1; }
sub STATE_OFF () { 0; }
sub STATE_CLOSED () { 0; }
sub STATE_DOWN () { 0; }
sub STATE_LEFT () { 0; }

sub SIG_UNKNOWN () { 99999; }

sub STATE_FLIP () { -1; }

sub SIG_LEVEL_WON () { 10; }
sub SIG_LEVEL_LOST () { -10; }

use vars qw/$sig_names $sig_codes/;

BEGIN
  {
  $sig_names =
  {
  SIG_LEVEL_WON() => 'SIG_LEVEL_WON',
  SIG_LEVEL_LOST() => 'SIG_LEVEL_LOST',
  SIG_FLIP() => 'SIG_FLIP',
  SIG_DIE() => 'SIG_DIE',
  SIG_KILLED() => 'SIG_KILLED',
  SIG_ACTIVATE() => 'SIG_ACTIVATE',
  SIG_DEACTIVATE() => 'SIG_DEACTIVATE',
  SIG_ON() => 'SIG_ON',
  SIG_OFF() => 'SIG_OFF',
  SIG_STATE_0() => 'SIG_STATE_0',
  SIG_STATE_1() => 'SIG_STATE_1',
  SIG_STATE_2() => 'SIG_STATE_2',
  SIG_STATE_3() => 'SIG_STATE_3',
  SIG_STATE_4() => 'SIG_STATE_4',
  SIG_STATE_5() => 'SIG_STATE_5',
  SIG_STATE_6() => 'SIG_STATE_6',
  SIG_STATE_7() => 'SIG_STATE_7',
  SIG_STATE_8() => 'SIG_STATE_8',
  SIG_STATE_9() => 'SIG_STATE_9',
  SIG_STATE_10() => 'SIG_STATE_10',
  SIG_STATE_11() => 'SIG_STATE_11',
  SIG_STATE_12() => 'SIG_STATE_12',
  SIG_STATE_13() => 'SIG_STATE_13',
  SIG_STATE_14() => 'SIG_STATE_14',
  SIG_STATE_15() => 'SIG_STATE_15',
  SIG_NOW_0() => 'SIG_NOW_0',
  SIG_NOW_1() => 'SIG_NOW_1',
  SIG_NOW_2() => 'SIG_NOW_2',
  SIG_NOW_3() => 'SIG_NOW_3',
  SIG_NOW_4() => 'SIG_NOW_4',
  SIG_NOW_5() => 'SIG_NOW_5',
  SIG_NOW_6() => 'SIG_NOW_6',
  SIG_NOW_7() => 'SIG_NOW_7',
  SIG_NOW_8() => 'SIG_NOW_8',
  SIG_NOW_9() => 'SIG_NOW_9',
  SIG_NOW_10() => 'SIG_NOW_10',
  SIG_NOW_11() => 'SIG_NOW_11',
  SIG_NOW_12() => 'SIG_NOW_12',
  SIG_NOW_13() => 'SIG_NOW_13',
  SIG_NOW_14() => 'SIG_NOW_14',
  SIG_NOW_15() => 'SIG_NOW_15',
  };

  $sig_codes = {};
  # reverse map
  foreach my $key (keys %$sig_names)
    {
    $sig_codes->{ $sig_names->{$key} } = $key;
    }
  }

##############################################################################
# methods

sub invert
  {
  shift if ref($_[0]) || $_[0] eq 'Games::3D::Signal';
  my $signal = shift;

  $signal = -$signal if abs($signal < SIG_STATE_0);
  $signal;
  }

sub signal_from_state
  {
  my $state = shift;

  SIG_NOW_0 + $state;		# 0 => 100, 1 => 101 etc
  }

sub signal_name
  {
  my $sig = shift;

  my $s = $sig_names->{$sig} || 'SIG_UNKNOWN';

  $s ."($sig)";
  }

sub signal_by_name
  {
  my $sig = shift;

  $sig_codes->{$sig} || SIG_UNKNOWN;
  }

sub state_from_signal
  {
  my $sig = shift;

  if ($sig == SIG_ON)
    {
    $sig = STATE_ON;
    }
  elsif ($sig == SIG_OFF)
    {
    $sig = STATE_OFF;
    }
  elsif ($sig == SIG_FLIP)
    {
    $sig = STATE_FLIP;
    }
  else
    { 
    $sig -= SIG_STATE_0;
    }
  $sig;
  }

1;

__END__

=pod

=head1 NAME

Games::3D::Signal - export the signal and state names

=head1 SYNOPSIS

	use Games::3D::Signal qw/SIG_ON SIG_OFF/;

	$signal = Games::3D::Signal->invert($signal) if $signal == SIG_ON;

=head1 EXPORTS

Exports nothing on default. Can export signal and state names like:

  SIG_ON SIG_UP SIG_OPEN
  SIG_OFF SIG_CLOSE SIG_DOWN
  SIG_FLIP SIG_DIE
  SIG_ACTIVATE SIG_DEACTIVATE

  SIG_LEFT SIG_RIGHT
  STATE_ON STATE_UP STATE_OPEN
  STATE_OFF STATE_CLOSED STATE_DOWN

  SIG_KILLED 
  SIG_LEVEL_WON
  SIG_LEVEL_LOST
  invert

  STATE_0 STATE_1 STATE_2 STATE_3 STATE_4 STATE_5 STATE_6 STATE_7 STATE_8
  STATE_9 STATE_10 STATE_11 STATE_12 STATE_13 STATE_14 STATE_15
  
  SIG_STATE_0 SIG_STATE_1 SIG_STATE_2 SIG_STATE_3 SIG_STATE_4 SIG_STATE_5
  SIG_STATE_6 SIG_STATE_7 SIG_STATE_8 SIG_STATE_9 SIG_STATE_10 SIG_STATE_11
  SIG_STATE_12 SIG_STATE_13 SIG_STATE_14 SIG_STATE_15
  
  SIG_NOW_0 SIG_NOW_1 SIG_NOW_2 SIG_NOW_3 SIG_NOW_4 SIG_NOW_5
  SIG_NOW_6 SIG_NOW_7 SIG_NOW_8 SIG_NOW_9 SIG_NOW_10 SIG_NOW_11
  SIG_NOW_12 SIG_NOW_13 SIG_NOW_14 SIG_NOW_15

=head1 DESCRIPTION

This package just exports the signal and state names on request.

=head1 METHODS

=over 2

=item invert()

	$signal = Games::3D::Signal::invert($signal);

Invert a signal when the signal is SIG_ON or SIG_OFF (or one of it's
aliases like RIGHT, LEFT, UP, DOWN, CLOSE, or OPEN),

=item signal_name()

	print Games::3D::Signal::signal_name($signal);

Return the name of the signal.

=item signal_from_state()

	print Games::3D::Signal::signal_from_state($state);

Return the signal that should be send out when the C<$state> is reached.

=item state_from_signal()

	print Games::3D::Signal::state_from_signal($signal);

Given a signal like C<SIG_ON>, C<SIG_FLIP> or C<SIG_STATE_x>, will return
the new state that will result from receiving this signal.

=item signal_by_name()

	my $signal = Games::3D::Signal::signal_by_name('SIG_FLIP');

Converts a signal name to the signal number.

=back

=head1 AUTHORS

(c) 2002 - 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::Irrlicht>, L<Games::3D>.

=cut

