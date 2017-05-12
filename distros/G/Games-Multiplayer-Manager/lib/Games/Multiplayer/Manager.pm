package Games::Multiplayer::Manager;

use strict;
use warnings;

our $VERSION = '1.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		debug       => 0,
		'_games'    => {},
		'_handlers' => {},
		@_,
	};

	bless ($self,$class);

	return $self;
}

sub debug {
	my ($self,$msg) = @_;

	return unless $self->{debug};
	print "Games::Multiplayer::Manager::debug // $msg\n\n";

	return 1;
}

sub version {
	return $VERSION;
}

##########################################
## General Methods                      ##
##########################################

sub create {
	my $self = shift;
	my %in = @_;

	# Required data.
	my $id   = $in{id};
	my $name = $in{name};

	if (not defined $id) {
		$self->debug ("Error creating game: ID was not provided!");
		return 0;
	}
	if (not defined $name) {
		$self->debug ("Error creating game $id: Name was not provided!");
		return 0;
	}

	# Return 0 if the ID already exists.
	return 0 if exists $self->{_games}->{$id};

	# Create the game.
	$self->{_games}->{$id} = {
		'_players' => {},
		'name' => $in{name},
		@_,
	};

	# Return true.
	return 1;
}

sub destroy {
	my $self = shift;
	my %in = @_;

	# Required data.
	my $id = $in{id};

	# Return if the ID doesn't exist.
	if (!exists $self->{_games}->{$id}) {
		$self->debug ("Could not destroy $id: Doesn't exist!");
		return 0;
	}

	# Check the force and alert flags.
	my $force = $in{force} || 0;
	my $alert = $in{alert} || 1 unless $in{alert} == 0;
	my $msg   = $in{message} || "This game ($self->{_games}->{$id}->{name}) has been terminated.";

	# Array of players.
	my @count = keys %{$self->{_games}->{$id}->{_players}};

	# If not being forced...
	if ($force != 1) {
		# Only close if there are no players.
		if (scalar(@count) > 0) {
			$self->debug ("Could not destroy $id: Game isn't empty yet!");
			return 0;
		}
	}

	# If there were players, try and alert them.
	if (scalar(@count) > 0) {
		if ($alert == 1) {
			foreach my $player (@count) {
				# Broadcast to this player.
				$self->sendMessage (
					to      => $player,
					message => $msg,
				);
			}
		}
	}

	# Destroy the game.
	delete $self->{_games}->{$id};
	return 1;
}

sub setHandler {
	my $self = shift;
	my %in = @_;

	# Set these handlers.
	foreach my $key (keys %in) {
		$self->{_handlers}->{$key} = $in{$key};
	}

	return 1;
}

sub sendMessage {
	my $self = shift;

	# Send these to the broadcast handler.
	if (exists $self->{_handlers}->{broadcast}) {
		&{$self->{_handlers}->{broadcast}} (@_) || return 0;
	}

	return 1;
}

sub broadcast {
	my $self = shift;
	my $id = shift;
	my $msg = shift;

	return 0 unless exists $self->{_games}->{$id};

	# Send this to all users.
	foreach my $user (keys %{$self->{_games}->{$id}->{_players}}) {
		$self->sendMessage (
			to      => $user,
			message => $msg,
		);
	}

	return 1;
}

##########################################
## Game Methods                         ##
##########################################

sub queryGame {
	my $self = shift;
	my $id = shift;

	# See if this game exists.
	if (exists $self->{_games}->{$id}) {
		return 1;
	}

	return 0;
}

sub listGames {
	my $self = shift;

	# Get a list of all the games.
	my @list = keys %{$self->{_games}};

	return @list;
}

##########################################
## Player Methods                       ##
##########################################

sub addPlayer {
	my $self = shift;
	my $id = shift;
	my %in = @_;

	# Get specific data.
	my $name = $in{name};

	# Must be a name.
	if (length $name == 0) {
		$self->debug ("Could not add player to $id: Player name not defined!");
		return 0;
	}

	# This ID must exist.
	if (!exists $self->{_games}->{$id}) {
		$self->debug ("Could not add player to $id: Game doesn't exist!");
		return 0;
	}

	# Add them.
	$self->{_games}->{$id}->{_players}->{$name} = {
		id => $id,
		@_,
	};
	return 1;
}

sub dropPlayer {
	my $self = shift;
	my ($id,$name) = @_;

	# ID must exist.
	if (!exists $self->{_games}->{$id}) {
		$self->debug ("Could not drop player from $id: Game doesn't exist!");
		return 0;
	}

	# Name must exist.
	if (!exists $self->{_games}->{$id}->{_players}->{$name}) {
		$self->debug ("Could not drop player from $id: Name not defined!");
		return 0;
	}

	# Drop them.
	delete $self->{_games}->{$id}->{_players}->{$name};
	return 1;
}

sub findPlayer {
	my $self = shift;
	my $name = shift;

	# Find them.
	my @games = ();
	foreach my $game (keys %{$self->{_games}}) {
		foreach my $member (keys %{$self->{_games}->{$game}->{_players}}) {
			if ($member eq $name) {
				push (@games, $game);
			}
		}
	}

	# Return the array of game ID's.
	return @games;
}

sub queryPlayer {
	my $self = shift;
	my ($id,$name) = @_;

	# Return true if they exist.
	return 1 if exists $self->{_games}->{$id}->{_players}->{$name};
	return 0;
}

sub listPlayers {
	my $self = shift;
	my $id = shift;

	# ID must be defined.
	if (length $id == 0) {
		$self->debug ("Could not list players: ID not passed in!");
		return undef;
	}

	# ID must exist.
	if (!exists $self->{_games}->{$id}) {
		$self->debug ("Could not list players: Game $id doesn't exist!");
		return undef;
	}

	# Get the players.
	my @list = keys %{$self->{_games}->{$id}->{_players}};
	return @list;
}

1;
__END__

=head1 NAME

Games::Multiplayer::Manager - Perl extension for easy management of multiplayer games in
interactive environments.

=head1 SYNOPSIS

  use Games::Multiplayer::Manager;

  # Create a new game manager.
  my $game = new Games::Multiplayer::Manager ();

  # Set up broadcast handler.
  $game->setHandler (broadcast => sub {
    my $self = shift;
    print "Got message for $self->{to}: $self->{message}\n\n";
  });

  # Create a new game.
  $game->create (
    id   => "tag",
    name => "The Game of Tag",
  );

  # Add a player.
  $game->addPlayer ("tag",
    host => "Perl",
    name => "foo",
  );

  # Drop that player.
  $game->dropPlayer ("tag", "foo");

  # Destroy the game.
  $game->destroy ("tag");

=head1 DESCRIPTION

Games::Multiplayer::Manager is a simple interface for creating and managing multiplayer games
in interactive environments (for example, with IRC bots).

=head1 METHODS

=head2 new

Create a new game manager. This method should be called only once (a single manager
object can manage as many games as you need). You can also pass in default variables
(try to avoid any that begin with an underscore).

  my $manager = new Games::Multiplayer::Manager (debug => 1);

=head2 version

Returns the module's version.

  my $version = $manager->version;

=head2 create

Create a new game instance. Passed in are details on the game, which must include
a unique identifier and a name (you can pass in any extra data if you want to, but
not much else is used by the module itself).

This creates a new, empty game. To add players to it later, call the addPlayer
method with the same ID that you created the game with.

This method will return 0 if there was an error (most likely the ID was already in
use by another game).

  $manager->create (
    id   => "tag",
    name => "The Game of Tag",
  );

=head2 destroy

Destroy a game instance. Pass in arguments in hash form. The required element is the
ID of the game to destroy. Optional arguments are "force" (boolean) to force any
existing players out of the game. If that is true, another argument "alert" should
be provided to define whether or not the players should be told about the game being
terminated. You can also pass a "message" to be broadcasted to those players.

  $manager->destroy (
    id      => "tag",
    force   => 1,
    message => "Game terminated by an administrator.",
    alert   => 1,
  );

=head2 setHandler

Set a handler. Currently the only handler is for "broadcast" - your handler sub would
receive a hash containing "to" and "message"

  $manager->setHandler (broadcast => \&broadcast);

=head2 sendMessage

Send a message to a single person. This method is usually called from within the module.

  $manager->sendMessage (to => "foo", message => "Hello!");

=head2 broadcast

Send a message to all players in a given Game ID.

  $manager->broadcast ("tag", "Soandso has been tagged!");

=head1 GAME METHODS

=head2 queryGame

Check a game's existence. Pass in the Game ID. This method will return 1 if the game
exists, or 0 if it does not.

  my $exists = $manager->queryGame ("tag");

=head2 listGames

Returns an array of every Game ID that is currently in existence under this manager.

  my @games = $manager->listGames;

=head1 PLAYER METHODS

=head2 addPlayer

Add a player to an already created game. The first parameter is the Game ID, followed
by a hash that must contain (at least) a unique name for the player.

  $manager->addPlayer ("tag",
    name => "foo",
  );

=head2 dropPlayer

Remove a player from a game. The game ID must exist, and a name must be defined.

  $manager->dropPlayer ("tag", "foo");

=head2 findPlayer

Searches every existing game for a certain player. This method returns an array of each
Game ID that the player exists in.

  my @ids = $manager->findPlayer ("foo");

=head2 queryPlayer

Check a player's existence within a game. Returns true if they exist there.

  my $exists = $manager->queryPlayer ("tag", "foo");

=head2 listPlayers

Returns an array of players that exist in the passed in Game ID.

  my @players = $manager->listPlayers ("tag");

=head1 SEE ALSO

Nothing else to see at the moment.

=head1 CHANGES

  Version 1.01
  - Fixed a few bugs with arrays being returned by the module. It used to return "0"
    when the array would've been empty, causing $array[0] = 0. This has been fixed.
    empty arrays return empty now.
  - Revised the module page. The broadcast handler receives "to" and "message" as
    the hash keys, not "msg".
  - Fixed the test script; Makefile should install more smoothly now.

  Version 1.00
  - Initial release.

=head1 AUTHOR

Cerone Kirsle, E<lt>cerone@aichaos.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Games::Multiplayer::Manager - Multiplayer game management for interactive environments.
  Copyright (C) 2005  Cerone Kirsle

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


=cut