package Games::Tournament::Swiss;
$Games::Tournament::Swiss::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:35
# $Id: Swiss.pm 1360 2016-01-01 05:54:20Z drbean $

use warnings;
use strict;
use Carp;

use Games::Tournament::Swiss::Config;

use constant ROLES => @Games::Tournament::Swiss::Config::roles?
			@Games::Tournament::Swiss::Config::roles:
			Games::Tournament::Swiss::Config->roles;
use constant FIRSTROUND => $Games::Tournament::Swiss::Config::firstround;

use base qw/Games::Tournament/;

# use Games::Tournament::Swiss::Bracket;
#use Games::Tournament::Contestant::Swiss -mixin =>
#  qw/score scores rating title name pairingNumber oldId roles/;
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss::Procedure;
use Games::Tournament::Contestant::Swiss::Preference;

use List::Util qw/max min reduce sum first/;
use List::MoreUtils qw/any all/;

=head1 NAME

Games::Tournament::Swiss - FIDE Swiss Same-Rank Contestant Pairing 

=cut

=head1 SYNOPSIS

    @Games::Tournament::Swiss::roles = qw/Black White/;
    $tourney = Games::Tournament::Swiss->new($rounds, \@entrants);
    @rankedPlayers = $tourney->assignPairingNumbers;
    $tourney->initializePreferences;


    ...

    $tourney->collectCards(@games);
    @groups = $tourney->formBrackets($round);
    $round5 = $tourney->pairing( \@groups );
    $matches = $round5->matchPlayers;
    $round5->allocateColors;

=head1 DESCRIPTION

In a Swiss tournament, there is a pre-declared number of rounds, each contestant meets every other contestant zero or one times, and in each round contestants are paired with other players with the same, or similar, scores.

=head1 METHODS

=head2 assignPairingNumbers

 @rankings = $tourney->assignPairingNumbers;

Sets the participants pairing numbers, sorting on rating, title and name, and substitutes this for the id they had before (The id was, but is no longer, saved as oldId. But don't change id to pairingNumber. It will change with late entries.) This function uses Games::Tournament::rank. Before the first round, all scores are usually 0. A2

=cut

sub assignPairingNumbers {
    my $self    = shift;
    my @players = @{ $self->entrants };
    $self->log( 'Pairing numbers' );
    my $numbers = sub { join ', ',
	    map { $_->id . ": " . $_->pairingNumber } @players;
    };
    if ( all { $_->pairingNumber } @players ) {
	$self->log( &$numbers );
	return;
    }
    my @rankings = $self->rank(@players);
    foreach my $n ( 0 .. $#rankings ) {
	my $id = $rankings[$n]->id;
	my $player = $self->ided($id);
        $player->pairingNumber( $n+1 );
    }
    $self->log( &$numbers );
    $self->entrants( \@players );
}


=head2 initializePreferences

 @rankings = $tourney->initializePreferences;

Before the first round, the color (role) preference of the highest ranked player and the other odd-numbered players in the top half of the rankings is determined by lot. The preference of the even-numbered players in the top half is given to the other color. If there is only one player in the tournament, the preference is not initialized. The method assumes all entrants have a preference attribute. This accessor is given the player by the Games::Tournament::Contestant::Swiss constructor. We take care to put the players back in the same order that we got them from entrants method. Users may rely on the original order being maintained in web app cookies. E5

=cut

sub initializePreferences {
    my $self    = shift;
    my @players = @{ $self->{entrants} };
    my @rankings = $self->rank( @players );
    my ( $evenRole, $oddRole ) = $self->randomRole;
    my $p = int( @rankings / 2 );
    if ( $p == 0 ) {
        $rankings[ 0 ]->preference->sign('');
        $rankings[ 0 ]->preference->difference(0);
	return $self->entrants( \@rankings );
    }
    for ( my $n=0; $n <= $p-1; $n+=2 ) {
        $rankings[ $n ]->preference->sign($evenRole);
        $rankings[ $n ]->preference->difference(0);
    }
    for ( my $n=1; $n <= $p-1; $n+=2 ) {
        $rankings[ $n ]->preference->sign($oddRole);
        $rankings[ $n ]->preference->difference(0);
    }
    foreach my $n ( 0 .. $#rankings ) {
	my $id = $rankings[$n]->id;
	my $player = $self->ided($id);
	my $preference = $rankings[$n]->preference;
        $player->preference( $preference );
    }
    $self->entrants( \@players );
}


=head2 recreateCards

 $tourney->recreateCards( {
     round => $round,
     opponents => { 1 => 2, 2 => 1, 3 => 'Bye', 4 => '-' },
     roles => { 1 => 'W', 2 => 'B', 3 => 'Bye', 4 => '-' },
     floats => { 1 => 'U', 2=> 'D', 3 => 'Down', 4 => 'Not' }
 } )

From hashes of the opponents, roles and floats for each player in a round (as provided by a pairing table), draws up the original game cards for each of the matches of the round. Returned is a list of Games::Tournament::Card objects, with undefined result fields. Pairing numbers are not used. Ids are used. Pairing numbers change with late entries.

=cut

sub recreateCards {
    my $self  = shift;
    my $args    = shift;
    my $round = $args->{round};
    my $opponents = $args->{opponents};
    my $roles = $args->{roles};
    my $floats = $args->{floats};
    my $players = $self->entrants;
    my @ids = map { $_->id } @$players;
    my $absentees = $self->absentees;
    my @absenteeids = map { $_->id } @$absentees;
    my $test = sub {
	my %count = ();
	$count{$_}++ for @ids, keys %$opponents, keys %$roles, keys %$floats;
	return grep { $count{$_} != 4 } keys %count;
	    };
    carp "Game card not constructable for player $_ in round $round" for &$test;
    my (%games, @games);
    for my $id ( @ids )
    {
        next if $games{$id};
        my $player     = $self->ided($id);
        next if $round < $player->firstround;
	my $opponentId = $opponents->{$id};
        croak "Round $round: opponent info for Player $id?" unless $opponentId;
        my $opponent          = $self->ided($opponentId);
        my $opponentsOpponent = $opponents->{$opponentId};
        croak
"Player ${id}'s opponent is $opponentId, but ${opponentId}'s opponent is $opponentsOpponent, not $id in round $round"
          unless $opponentId eq 'Bye' or $opponentId eq 'Unpaired'
              or $opponentsOpponent eq $id;
        my $role         = $roles->{$id};
        my $opponentRole = $roles->{$opponentId};
        if ( $opponentId eq 'Unpaired' ) {
            croak "Player $id has $role, in round $round?"
              unless $player and $role eq 'Unpaired';
	    next;
	    next;
        }
        elsif ( $opponentId eq 'Bye' ) {
            croak "Player $id has $role role, in round $round?"
              unless $player and $role eq 'Bye';
        }
        else {
            croak
"Player $id is $role, and opponent $opponentId is $opponentRole, in round $round?"
              unless $player
                  and $opponent
                  and $role
                  and $opponentRole;

        }
        croak
"Player $id has same $role role as opponent $opponentId in round $round?"
          if $opponentId and defined $opponentRole and $role eq $opponentRole;
        my $contestants;
        if ( $opponentId eq 'Bye' ) { $contestants = { Bye => $player } }
        else { $contestants = { $role => $player, $opponentRole => $opponent } }
        my $game = Games::Tournament::Card->new(
            round       => $round,
            contestants => $contestants,
            result      => undef
        );
        my $float = $floats->{$id};
        $game->float( $player, $float );

        unless ( $opponentId eq 'Bye' ) {
            my $opponentFloat = $floats->{$opponentId};
            $game->float( $opponent, $opponentFloat );
        }
        $games{$id}         = $game;
        $games{$opponentId} = $game;
        push @games, $game;
    }
    return @games;
}


=head2 collectCards

 $play = $tourney->collectCards( @games );
  next if $htable->{$player1->id}->{$player2->id};

Records @games after they have been played. Stored as $tourney's play field, keyed on round and ids of players.  Returns the new play field. Updates player scores, preferences, unless the player forfeited the game or had a Bye. TODO Die (or warn) if game has no results TODO This has non-Swiss subclass elements I could factor out into a method in Games::Tournament. TODO What if player is matched more than one time in the round, filling in for someone? XXX It looks like all the games have to be the same round, or you have to collect all cards in one round before collecting cards in following rounds. XXX I'm having problems with recording roles. I want to be lazy about it, and trust the card I get back before the next round. The problem with this is, I may be getting the role from the wrong place. It should come from the card, and is a role which was assigned in the previous round, and is only now being recorded, at this point between the previous round and the next round. Or is the problem copying by value rather than reference of the entrants? Now I also need to record floats. It would be good to do this at the same time as I record roles. The card is the appropriate place to get this info according to A4. 

=cut

sub collectCards {
    my $self     = shift;
    my @games    = @_;
    my $play     = $self->play || {};
    # my @entrants = @{ $self->entrants };
    my %games;
    for my $game ( @games )
    {
	my $round = $game->round;
	carp "round $round is not a number." unless $round =~ m/^\d+$/;
	push @{ $games{$round} }, $game;
    }
    for my $round ( sort { $a <=> $b } keys %games )
    {
	my $games =  $games{$round}; 
	for my $game ( @$games ) {
	    my @players = $game->myPlayers;
	    for my $player ( @players ) {
		my $id       = $player->id;
		my $entrant = $self->ided($id);
		my $oldroles = $player->roles;
		my $scores   = $player->scores;
		my ( $role, $float, $score );
		$role             = $game->myRole($player);
		$float            = $game->myFloat($player);
		$scores->{$round} = ref $game->result eq 'HASH'? 
			    $game->result->{$role}: undef;
		$score = $scores->{$round};
		#carp
		#  "No result on card for player $id as $role in round $round,"
		#	unless $score;
		$game ||= "No game";
		$play->{$round}->{$id} = $game;
		$entrant->scores($scores);
		carp "No record in round $round for player $id $player->{name},"
		  unless $play->{$round}->{$id};
		$entrant->roles( $round, $role );
		$entrant->floats( $round, $float );
		$entrant->floating('');
		$entrant->preference->update( $entrant->rolesPlayedList ) unless
		    $score and ( $score eq 'Bye' or $score eq 'Forfeit' );
;
	    }
	}
    }
    $self->play($play);
}


=head2 orderPairings

 @schedule = $tourney->orderPairings( @games );

Tables are ordered by scores of the player with the higher score at the table, then the total scores of the players (in other words, the scores of the other player), then the A2 ranking of the higher-ranked player, in that order. F1

=cut

sub orderPairings {
    my $self     = shift;
    my @games     = @_;
    my $entrants = $self->entrants;
    my @rankedentrants = $self->rank(@$entrants);
    my %ranking = map { $rankedentrants[$_]->id => $_ } 0 .. $#rankedentrants;
    my @orderings = map { 
		    my @players = $_->myPlayers;
		    my @scores = map { $_->score || 0 } @players;
		    my $higherscore = max @scores;
		    my $totalscore = sum @scores;
		    my @rankedplayers = $self->rank( @players );
		    {	higherscore => $higherscore,
			totalscore => $totalscore,
			higherranking => $ranking{$rankedplayers[0]->id} };
		} @games;
    my @neworder = map { $games[$_] } sort {
	    $orderings[$b]->{higherscore} <=> $orderings[$a]->{higherscore} ||
	    $orderings[$b]->{totalscore} <=> $orderings[$a]->{totalscore} ||
	    $orderings[$a]->{higherranking} <=> $orderings[$b]->{higherranking}
		    } 0 .. $#orderings;
    return @neworder;
}


=head2 publishCards

 $schedule = $tourney->publishCards( @games );

Stores @games, perhaps before they have been played, as $tourney's play field, keyed on round and ids of players.  Returns the games in F1 ordering.

=cut

sub publishCards {
    my $self     = shift;
    my $play     = $self->play || {};
    my @entrants = @{ $self->entrants };
    my @games    = @_;
    for my $game (@games) {
        my $round       = $game->round;
        my $contestants = $game->contestants;
        my @players     = map { $contestants->{$_} } keys %$contestants;
        for my $player (@players) {
            my $id      = $player->id;
            my $entrant = $self->ided($id);
            die "Player $id $entrant in round $round?"
              unless $entrant
              and $entrant->isa("Games::Tournament::Contestant::Swiss");
            $play->{$round}->{$id} = $game;
        }
    }
    $self->orderPairings( @games );
}


=head2 myCard

 $game = $tourney->myCard(round => 4, player => 13301616);

Finds match from $tourney's play accessor, which is keyed on round and IDS of players. 'player' is id of player.

=cut

sub myCard {
    my $self    = shift;
    my %args    = @_;
    my $round   = $args{round};
    my $id  = $args{player};
    my $roundmatches = $self->{play}->{$round};
    return $roundmatches->{$id};
}


=head2 formBrackets

 @groups = $tourney->formBrackets

Returns for the next round a hash of Games::Tournament::Swiss::Bracket objects grouping contestants with the same score, keyed on score. Late entrants without a score cause the program to die. Some groups may have odd numbers of players, etc, and players will have to be floated to other score groups. A number, from 1 to the total number of brackets, reflecting the order of pairing, is given to each bracket.

=cut

sub formBrackets {
    my $self    = shift;
    my $players = $self->entrants;
    my $absentees = $self->absentees;
    my %hashed;
    my %brackets;
    foreach my $player (@$players) {
	my $id = $player->id;
	next if any { $id eq $_->id } @$absentees;
        my $score = defined $player->score ? $player->score : 0;
        # die "$player has no score. Give them a zero, perhaps?"
        #   if $score eq "None";
        $hashed{$score}{ $player->pairingNumber } = $player;
    }
    my $number = 1;
    foreach my $score ( reverse sort keys %hashed ) {
        my @members;
        foreach
          my $pairingNumber ( sort { $a <=> $b } keys %{ $hashed{$score} } )
        {
            push @members, $hashed{$score}{$pairingNumber};
        }
        use Games::Tournament::Swiss::Bracket;
        my $group = Games::Tournament::Swiss::Bracket->new(
            score   => $score,
            members => \@members,
	    number => $number
        );
        $brackets{$score} = $group;
	$number++;
    }
    return %brackets;
}

=head2 pairing

 $pairing = $tourney->pairing( \@groups );

Returns a Games::Tournament::Swiss::Procedure object. Groups are Games::Tournament::Swiss::Brackets objects of contestants with the same score and they are ordered by score, the group with the highest score first, and the group with the lowest score last. This is the point where round i becomes round i+1. But the program is expected to update the Games::Tournament::Swiss object itself. (Why?)

=cut

sub pairing {
    my $self     = shift;
    my $entrants = $self->entrants;
    my $brackets = shift;
    my $round    = $self->round;
    return Games::Tournament::Swiss::Procedure->new(
        round        => $round + 1,
        brackets     => $brackets,
        whoPlayedWho => $self->whoPlayedWho,
        colorClashes => $self->colorClashes,
        byes         => $self->byesGone,
    );
}


=head2 compatible

	$games = $tourney->compatible
	next if $games->{$alekhine->pairingNumber}->{$capablanca->pairingNumber}

Returns an anonymous hash, keyed on the ids of @grandmasters, indicating whether or not the individual @grandmasters could play each other in the next round. But what is the next round? This method uses the whoPlayedWho and colorClashes methods to remove incompatible players.

=cut

sub compatible {
    my $self     = shift;
    my $players  = $self->entrants;
    my @ids      = map { $_->id } @$players;
    my $play     = $self->play;
    my $dupes    = $self->whoPlayedWho;
    my $colorbar = $self->colorClashes;
    my $compat;
    for my $id1 (@ids) {

        for my $id2 ( grep { $_ != $id1 } @ids ) {
            $compat->{$id1}->{$id2} = 1
              unless exists $dupes->{$id1}->{$id2}
              or exists $colorbar->{$id1}->{$id2};
        }
    }
    return $compat;
}


=head2 whoPlayedWho

	$games = $tourney->whoPlayedWho
	next if $games->{$alekhine->pairingNumber}->
	    {$capablanca->pairingNumber}

Returns an anonymous hash, keyed on the ids of the tourney's entrants, of the round in which individual entrants met. Don't forget to collect scorecards in the appropriate games first! (No tracking of how many times players have met if they have met more than once!) Do you know what round it is? B1 XXX Unplayed pairings are not considered illegal in future rounds. F2 See also Games::Tournament::met.

=cut

sub whoPlayedWho {
    my $self    = shift;
    my $players = $self->entrants;
    my @ids     = map { $_->id } @$players;
    my $absentees = $self->absentees;
    my @absenteeids     = map { $_->id } @$absentees;
    my $play    = $self->play;
    my $dupes;
    my $lastround = $self->round;
    for my $round ( FIRSTROUND .. $lastround ) {
        for my $id (@ids) {
            my $player = $self->ided($id);
            die "No player with $id id in round $round game of @ids"
              unless $player;
            my $game = $play->{$round}->{$id};
            if ( $game and $game->can("myRole") ) {
		next if $game->result and $game->result eq 'Bye';
                my $role = $game->myRole($player);
                die
	"Player $id, $player->{name}'s role is $role, in round $round?"
                  unless any { $_ eq $role } ROLES, 'Bye';
		next if $game->result and exists $game->result->{$role} and
			$game->result->{$role} eq 'Forfeit';
                if ( any { $role eq $_ } ROLES ) {
                    my $otherRole = first { $role ne $_ } ROLES;
                    my $opponent = $game->contestants->{$otherRole};
                    $dupes->{$id}->{ $opponent->id } = $round;
                }
            }
	    elsif ( $player->firstround > $round or
		any { $id eq $_ } @absenteeids ) { next }
            else { warn "Player ${id} game in round $round?"; }
        }
    }
    return $dupes;
}


=head2 colorClashes

	$nomatch = $tourney->colorClashes
	next if $nomatch->{$alekhine->id}->{$capablanca->id}

Returns an anonymous hash, keyed on the ids of the tourney's entrants, of a color (role) if 2 of the individual @grandmasters both have an absolute preference for it in the next round and so can't play each other (themselves). Don't forget to collect scorecards in the appropriate games first! B2

=cut

sub colorClashes {
    my $self    = shift;
    my $players = $self->entrants;
    my @id      = map { $_->id } @$players;
    my $clashes;
    for my $player ( 0 .. $#$players ) {
        for ( 0 .. $#$players ) {
            $clashes->{ $id[$player] }->{ $id[$_] } =
              $players->[$player]->preference->role
              if $players->[$player]->preference->role
              and $players->[$_]->preference->role
              and $players->[$player]->preference->role eq
              $players->[$_]->preference->role
              and $players->[$player]->preference->strength eq 'Absolute'
              and $players->[$player]->preference->strength eq
              $players->[$_]->preference->strength;
        }
    }
    return $clashes;
}

=head2 byesGone

	next if $tourney->byesGone($grandmasters)

Returns an anonymous hash of either the round in which the tourney's entrants had a 'Bye' or the empty string, keyed on @$grandmasters' ids. If a grandmaster had more than one bye, the last one is returned. Don't forget to collect scorecards in the appropriate games first! B1

=cut


sub byesGone {
    my $self    = shift;
    my $players = $self->entrants;
    my @ids     = map { $_->id } @$players;
    my $absentees = $self->absentees;
    my @absenteeids     = map { $_->id } @$absentees;
    my $play    = $self->play;
    my $byes = {};
    my $round = $self->round;
    for my $round ( FIRSTROUND .. $round ) {
        for my $id (@ids) {
            my $player = $self->ided($id);
            my $game   = $play->{$round}->{$id};
            if ( $game and $game->can("myRole") ) {
                eval { $game->myRole($player) };
                die "Role of player $id in round $round? $@"
                  if not $player or $@;
                my $role = $game->myRole($player);
                if ( $role eq 'Bye' ) {
                    $byes->{$id} = $round;
                }
            }
	    elsif ( $player->firstround > $round or
		any { $id eq $_ } @absenteeids ) { next }
            else { warn "Player ${id} had Bye in round $round?"; }
        }
    }
    return $byes;
}

=head2 incompatibles

	$nomatch = $tourney->incompatibles(@grandmasters)
	next if $nomatch->{$alekhine->id}->{$capablanca->id}

Collates information from the whoPlayedWho and colorClashes methods to show who cannot be matched or given a bye in the next round, returning an anonymous hash keyed on the ids of @grandmasters. B1,2 C1,6

=cut

sub incompatibles {
    my $self              = shift;
    my $oldOpponents      = $self->whoPlayedWho;
    my $colorIncompatible = $self->colorClashes;
    my $players           = $self->entrants;
    my @id                = map { $_->id } @$players;
    my $unavailables;
    for my $player ( 0 .. $#$players ) {
        for ( 0 .. $#$players ) {
            my $color = $colorIncompatible->{ $id[$player] }->{ $id[$_] };
            my $round = $oldOpponents->{ $id[$player] }->{ $id[$_] };
            $unavailables->{ $id[$player] }->{ $id[$_] } = $color if $color;
            $unavailables->{ $id[$player] }->{ $id[$_] } ||= $round if $round;
        }
    }
    return $unavailables;
}


=head2 medianScore

 $group = $tourney->medianScore($round)

Returns the score equal to half the number of rounds that have been played. Half the contestants will have scores above or equal to this score and half will have ones equal to or below it, assuming everyone has played every round. What IS the number of rounds played, again?

=cut

sub medianScore {
    my $self  = shift;
    my $round = shift;
    return $round / 2;
}

=head2 rounds

	$tourney->rounds

Gets/sets the total number of rounds to be played in the competition

=cut

sub rounds {
    my $self   = shift;
    my $rounds = shift;
    if ( defined $rounds ) { $self->{rounds} = $rounds; }
    elsif ( $self->{rounds} ) { return $self->{rounds}; }
}


=head2 size

$size = 'Maxi' if $tourney->size > 2**$tourney->rounds

Gets the number of entrants

=cut

sub size {
    my $self = shift;
    return scalar @{ $self->entrants };
}

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-swiss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Swiss

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Swiss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Swiss>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Swiss>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Swiss>

=back

=head1 ACKNOWLEDGEMENTS

See L<http://www.fide.com/official/handbook.asp?level=C04> for the FIDE's Swiss rules.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Swiss

# vim: set ts=8 sts=4 sw=4 noet:
