package Games::Tournament::Card;
$Games::Tournament::Card::VERSION = '0.21';
# Last Edit: 2011  2月 27, 21時34分46秒
# $Id: $

use warnings;
use strict;
use Carp;

use List::Util qw/min reduce sum first/;
use List::MoreUtils qw/any all/;
use Scalar::Util qw/looks_like_number/;

use constant ROLES => @Games::Tournament::Swiss::Config::roles?
			@Games::Tournament::Swiss::Config::roles:
			Games::Tournament::Swiss::Config->roles;

=head1 NAME

Games::Tournament::Card - A record of the results of a match

=cut

=head1 SYNOPSIS

    $game = Games::Tournament:Card->new(round => 1, contestants => {Black => $knicks, White => $deepblue}, result => { Black => 'Win', White => 'Loss' });

=head1 DESCRIPTION

In a tournament, matches take place in rounds between contestants, who are maybe floated, and who have roles, and there is a result for these matches, which can be written on a card. 

=head1 METHODS

=head2 new

    $game = Games::Tournament:Card->new(
	    round => 1,
	    contestants => {Black => $knicks, White => $deepblue},
	    result => { Black => 'Win', White => 'Loss' },
	    floats => { Black => 'Up', White => 'Down' }, or 
	    floats => { Black => 'Not', White => 'Not' }
    );
    $bye = Games::Tournament:Card->new(
	    round => 1,
	    contestants => {Bye => $player},
	    result => "Bye"
	    floats => 'Down' );

'contestants' is a hash ref of player objects, keyed on Black and White, or Home and Away, or some other role distinction that needs to be balanced over the tournament. The players are probably instances of the Games::Tournament::Contestant::Swiss class. 'result' is a hash reference, keyed on the same keys as contestants, containing the results of the match. 'floats' is a hash of  which role was floated up and which down. The default is neither contestant was floated, and 'Down' for a Bye. A4. What are the fields in Forfeits and byes? Forfeit and Tardy have no special form, other than { White => 'Forfeit', Black => 'Tardy' }. Bye is { Bye => $player }. TODO Perhaps the fields should be Winner and Loser, and Down and Up?

=cut 

sub new {
    my $self = shift;
    my %args = @_;
    return bless \%args, $self;
}


=head2 canonize

    $game->canonize

Fleshes out a partial statement of the result. From an abbreviated match result (eg, { Black => 'Win' }), works out a canonical representation (eg, { Black => 'Win', White => 'Loss' }). A bye result is represented as { Bye => 'Bye' }.

=cut 

sub canonize {
    my $self        = shift;
    my $round       = $self->round;
    my $contestants = $self->contestants;
    my $result      = $self->result;
    my %result;
    my %roles = map { $contestants->{$_}->{id} => $_ } keys %$contestants;
    warn
"Incomplete match of @{[values( %roles )]} players @{[map {$_->id} values %$contestants]} in round $round.\n"
      unless keys %roles == 2
      or grep m/bye/i, values %roles;
  ROLE: foreach my $contestant ( values %$contestants ) {
        my $role = $roles{ $contestant->{id} };
        if ( $role eq 'Bye' ) {
                $result{$role} = $result->{$role} = 'Bye';
            }
        elsif ( exists $result->{$role} ) {
            if ( $result->{$role} =~ m/^(?:Win|Loss|Draw|Forfeit)$/i ) {
                $result{$role} = $result->{$role};
            }
            else {
                warn
"$result->{$role} result for player $contestant->{id} in round $round";
            }
            next ROLE;
        }
        elsif ( values %$contestants != 1 ) {
            my @opponents =
              grep { $contestant->id ne $_->id } values %$contestants;
            my $opponent = $opponents[0];
            my $other    = $roles{ $opponent->id };
            if ( exists $result->{$other} ) {
                $result{$role} = 'Loss'
                  if $result->{$other} =~ m/^Win$/i;
                $result{$role} = 'Win'
                  if $result->{$other} =~ m/^Loss$/i;
                $result{$role} = 'Draw'
                  if $result->{$other} =~ m/^Draw$/i;
            }
            else {
                warn
"$result->{$role}, $result->{$other} result for player $contestant->{id} and opponent $opponent->{id} in round $round";
            }
        }
	else {
		die "Not a Bye, but no result or no partner";
	}
    }
    $self->result( \%result );
}


=head2 myResult

    $game->myResult($player)

Returns the result for $player from $game, eg 'Win', 'Loss' or 'Draw'.
TODO Should return 0,0.5,1 in numerical context.

=cut 

sub myResult {
    my $self       = shift;
    my $contestant = shift;
    $self->canonize;
    my $contestants = $self->contestants;
    my $result      = $self->result;
    my %result;
    my %roles = map { $contestants->{$_}->id => $_ } keys %$contestants;
    my $role = $roles{ $contestant->id };
    return $result->{$role};
}


=head2 myPlayers

    $game->myPlayers

Returns an array of the players from $game, eg ($alekhine, $yourNewNicks) in ROLES order.

=cut 

sub myPlayers {
    my $self        = shift;
    my $contestants = $self->contestants;
    my @players;
    for my $role ( ROLES ) {
	push @players, $contestants->{$role} if exists $contestants->{$role};
    }
    push @players, $contestants->{Bye} if exists $contestants->{Bye};
    return @players;
}


=head2 hasPlayer

    $game->hasPlayer($player)

A predicate to perform a test to see if a player is a contestant in $game. Because different objects may refer to the same player when copied by value, use id to decide.

=cut 

sub hasPlayer {
    my $self        = shift;
    my $player = shift;
    my @contestants = $self->myPlayers;
    any { $player->id eq $_->id } @contestants;
}


=head2 myOpponent

    $game->myOpponent($player)

Returns the opponent of $player from $game. If $player has a Bye, return a Games::Tournament::Contestant::Swiss object with name 'Bye', and id 'Bye'.

=cut 

sub myOpponent {
    my $self       = shift;
    my $contestant = shift;
    my $id = $contestant->id;
    my $contestants = $self->contestants;
    my @contestants = values %$contestants;
    my %dupes;
    for my $contestant ( @contestants )
    {
	die "Player $contestant isn't a contestant"
	unless $contestant and
		$contestant->isa('Games::Tournament::Contestant::Swiss');
    }
    my @dupes = grep { $dupes{$_->id}++ } @contestants;
    croak "Players @dupes had more than one role" if @dupes;
    my $opponent = first { $id ne $_->id } @contestants;
    $opponent = Games::Tournament::Contestant::Swiss->new(
	name => "Bye", id => "Bye") if $self->isBye;
    return $opponent;
}


=head2 myRole

    $game->myRole($player)

Returns the role for $player from $game, eg 'White', 'Banker' or 'Away'.

=cut 

sub myRole {
    my $self       = shift;
    my $contestant = shift;
    my $id = $contestant->id;
    my $round = $self->round;
    my $contestants = $self->contestants;
    my @contestants = $self->myPlayers;
    my $players;
    $players .= " $_: " . $contestants->{$_}->id for keys %$contestants;
    unless ( $self->hasPlayer($contestant) ) {
	carp "Player $id not in Round $round. Contestants are $players.";
	return;
    }
    my %dupes;
    for my $contestant ( @contestants )
    {
	die "Player $contestant isn't a contestant"
	unless $contestant and
		$contestant->isa('Games::Tournament::Contestant::Swiss');
    }
    my @dupes = grep { $dupes{$_->id}++ } @contestants;
    croak "Player $id not in Round $round match. Contestants are $players."
	    if @dupes;
    my %roleReversal;
    for my $role ( keys %$contestants )
    {
	my $id = $contestants->{$role}->id;
	$roleReversal{$id} = $role;
    }
    my $role        = $roleReversal{ $id };
    carp "No role for player $id in round " . $self->round unless $role;
    return $role;
}


=head2 myFloat

    $game->myFloat($player)

Returns the float for $player in $game, eg 'Up', 'Down' or 'Not'.

=cut 

sub myFloat {
    my $self       = shift;
    my $contestant = shift;
    # $self->canonize;
    my $float = $self->float($contestant);
    return $float;
}


=head2 opponentRole

    Games::Tournament::Card->opponentRole( $role )

Returns the role of the opponent of the player in the given role. Class method.

=cut 

sub opponentRole {
    my $self       = shift;
    my $role = shift;
    my %otherRole;
    @otherRole{ (ROLES) } = reverse (ROLES);
    return $otherRole{ $role };
}


=head2 round

 $game->round

Returns the round in which the match is taking place.

=cut

sub round {
    my $self = shift;
    return $self->{round};
}


=head2 contestants

	$game->contestants

Gets/sets the participants as an anonymous array of player objects.

=cut

sub contestants {
    my $self        = shift;
    my $contestants = shift;
    if ( defined $contestants ) { $self->{contestants} = $contestants; }
    else { return $self->{contestants}; }
}


=head2 result

	$game->result

Gets/sets the results of the match.

=cut

sub result {
    my $self   = shift;
    my $result = shift;
    if ( defined $result ) { $self->{result} = $result; }
    else { return $self->{result}; }
}


=head2 equalScores

	$game->equalScores

Tests whether the players have equal scores, returning 1 or ''. If scores were not equal, they are (should be) floating.

=cut

sub equalScores {
    my $self   = shift;
    my $contestants = $self->contestants;
    my @score = map { $contestants->{$_}->score } ROLES;
    return unless looks_like_number $score[0];
    return all { $score[0] == $_ } @score;
}


=head2 higherScoreRole

	$game->higherScoreRole

Returns the role of the player with the higher score, returning '', if scores are equal.

=cut

sub higherScoreRole {
    my $self   = shift;
    my $contestant = $self->contestants;
    my @score = map { $contestant->{$_}->score } ROLES;
    return (ROLES)[0] if $score[0] > $score[1];
    return (ROLES)[1] if $score[0] < $score[1];
    return '';
}


=head2 floats

	$game->floats

Gets/sets the floats of the match. Probably $game->float($player, 'Up') is used however, instead.

=cut

sub floats {
    my $self   = shift;
    my $floats = shift;
    if ( defined $floats ) { $self->{floats} = $floats; }
    else { return $self->{floats}; }
}


=head2 float

	$card->float($player[,'Up|Down|Not'])

Gets/sets whether the player was floated 'Up', 'Down', or 'Not' floated. $player->floats is not changed. This takes place in $tourney->collectCards. TODO what if $player is 'Bye'?

=cut

sub float {
    my $self   = shift;
    my $player = shift;
    die "Player is $player ref"
      unless $player and $player->isa('Games::Tournament::Contestant::Swiss');
    my $role = $self->myRole($player);
    croak "Player " . $player->id . " has $role role in round $self->{round}?"
      unless $role eq 'Bye'
      or $role     eq (ROLES)[0]
      or $role     eq (ROLES)[1];
    my $float = shift;
    if ( $role eq 'Bye' ) { return 'Down'; }
    elsif ( defined $float ) { $self->{floats}->{$role} = $float; }
    elsif ( $self->{floats}->{$role} ) { return $self->{floats}->{$role}; }
    else { return 'Not'; }
}

=head2 isBye

	$card->isBye

Returns whether the card is for a bye rather than a game between two oppponents.

=cut

sub isBye {
    my $self   = shift;
    my $contestants = $self->contestants;
    my @status = keys %$contestants;
    return 1 if @status == 1 and any { $_ eq 'Bye' } @status;
    return 0 if @status == 2 and all { $_ eq (ROLES)[0] or $_ eq (ROLES)[1] } @status;
    return;
}

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-match at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Card>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Card

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Card>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Card>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Card>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Card>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Card

# vim: set ts=8 sts=4 sw=4 noet:
