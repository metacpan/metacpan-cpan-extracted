package Games::Go::GTP;

use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = 0.07;
@ISA     = qw(Exporter);
@EXPORT  = qw(&gtpcommand);

my %known_commands = (
  protocol_version      => \&protocol_version,
  name                  => \&name,
  version               => \&version,
  known_command         => \&known_command,
  list_commands         => \&list_commands,
  quit                  => \&quit,
  boardsize             => \&boardsize,
  clear_board           => \&clear_board,
  komi                  => \&komi,
  play                  => \&play,
  genmove               => \&genmove,
  place_free_handicap   => \&place_free_handicap,
  set_free_handicap     => \&set_free_handicap,
  final_status_list     => \&final_status_list,
  undo                  => \&undo,
  'kgs-genmove_cleanup' => \&kgs_genmove_cleanup,
  'kgs-game_over'       => \&kgs_game_over,
);

my $PROTOCOL_VERSION_NO = 2;
my $ENGINE_NAME = 'my engine';
my $ENGINE_VERSION = '0.01';

sub engineName {
  my $ename = shift;
  $ENGINE_NAME = $ename if defined $ename;
  return $ENGINE_NAME
}

sub engineVersion {
  my $eversion = shift;
  $ENGINE_VERSION = $eversion if defined $eversion;
  return $ENGINE_VERSION
}

sub protocolVersion {
  my $pversion = shift;
  $PROTOCOL_VERSION_NO = $pversion if defined $pversion;
  return $PROTOCOL_VERSION_NO
}

sub gtpcommand {
  my ($command, $res, @params);
  my $id = '';
  my $status;
  if ($_[0] =~ /^\d/o) {
    $id = shift;
  }
  $command = shift;
  if (exists $known_commands{$command}) {
    my ($result, $output);
    ($result, $output, $status) = $known_commands{$command}->(@_);
    $output ||= '';
    $res = join '', $result, $id, ' ', $output, "\n\n";
  } else {
    $res = join '', '?', $id, ' unknown command', "\n\n" ;
  }
  if ($command eq 'quit') {
    $res = 0;
  }
  return $res, $status
}

sub protocol_version {
  return '=', $PROTOCOL_VERSION_NO;
}

sub name {
  return '=', $ENGINE_NAME;
}

sub version {
  return '=', $ENGINE_VERSION;
}

sub known_command {
  my ($command) = @_;
  my $response = (exists $known_commands{$command}) ? 'true' : 'false';
  return '=', $response;
}

sub list_commands {
  my $commands = join "\n", keys %known_commands;
  return '=', $commands;
}

sub quit {
  return '=';
}

sub boardsize {
  my ($size, $referee, $player) = @_;
  eval {$referee->size($size)};
  return '?',' unacceptable size' if $@ or $size > 25;
  $player->size($size);
  $referee->restore(0);
  $player->initboard($referee);
  return '=', undef, 1 # so the caller of this module knows we're in a game
}

sub clear_board {
  my ($referee, $player) = @_;
  $referee->restore(0);
  $player->initboard($referee);
  return '='
}

sub komi { # need to tell Referee?
  my ($komi) = @_;
  return '='
}

sub play {
  my ($colour, $GTPpoint, $referee, $player) = @_;
  $colour = convertcolour($colour);
  eval {$referee->play($colour, $GTPpoint)};
  return '?', ' illegal move' if $@;
  return '='
}

sub genmove {
  my ($colour, $referee, $player) = @_;
  $colour = convertcolour($colour);
  $player->update($colour, $referee);
  my $move = $player->chooselegalmove($colour, $referee);
  $referee->play($colour, $move);
  return '=', $move;
}

sub place_free_handicap {
  my ($handicap, $referee, $player) = @_;
  my @moves;
  for (1..$handicap) {
    $player->update('B', $referee);
    my $move = $player->chooselegalmove('B', $referee);
    $referee->setup('AB', join ',', $move);
    push @moves, $move;
  }
  return '=', join ' ', @moves
}

sub set_free_handicap {
  my $player  = pop;
  my $referee = pop;
  $referee->setup('AB', join ',', @_);
  return '='
}

sub final_status_list {
  my ($statustype, $referee, $player) = @_;
  my $pref;
  for ($statustype) {
    if (lc $_ eq 'alive') {
      $pref = $referee->listallalive;
      last
    }
    if (lc $_ eq 'dead') {
      $pref = $referee->listalldead;
      last
    }
    if (lc $_ eq 'seki') {
      last
    }
    return '?', ' syntax error'
  }
  return '=', join ' ', @$pref
}

sub kgs_genmove_cleanup {
  my ($colour, $referee, $player) = @_;
  $player->{_KGScleanup} = 1;
  my ($status, $res) = genmove(@_);
  $player->{_KGScleanup} = 0;
  return $status, $res
}

sub undo {
  my ($referee, $player) = @_;
  eval { $referee->restore(-1) };
  return '?', ' cannot undo' if $@;
  return '='
}

sub kgs_game_over {
  return '=', undef, 0
}

sub convertcolour {
  return uc substr shift, 0, 1
}

1;

=head1 NAME

Games::Go::GTP - Interact with a server or Go playing program using GTP

=head1 SYNOPSIS

  use Games::Go::GTP;
  use Games::Go::Player;
  my $referee = new Games::Go::Referee;
  my $player  = new Games::Go::Player;
  ...
  my ($res, $status) = Games::Go::GTP::gtpcommand(@args, $referee, $player);

=head1 DESCRIPTION

I would like to make this module more abstract, but I'm not sure how.
For example, it assumes that Player, which is the code that generates a move (supply your own!),
supports the following methods:

  $player->size($somesize); # eg, $player->size(19), issued following the GTP command boardsize
  $player->initboard($referee); # following the GTP command clear_board
  $player->update($colour, $referee); # following GTP play
  $player->chooselegalmove($colour, $referee); # following GTP genmove
  $player->{_KGScleanup} = 1; # following the KGS specific kgs_genmove_cleanup

=head2 General use

  An example of a script to run a bot on KGS is given in the example folder.


=head1 METHODS

=head2 engineName, engineVersion, protocolVersion

  use Games::Go::GTP;
  Games::Go::GTP::engineName('MYNAME');  # set MYNAME to anything you like
  Games::Go::GTP::engineVersion('0.01'); # set '0.01' to anything you like
  Games::Go::GTP::protocolVersion('2');  # leave this one alone ?

=head1 AUTHOR (version 0.01)

DG

=cut
