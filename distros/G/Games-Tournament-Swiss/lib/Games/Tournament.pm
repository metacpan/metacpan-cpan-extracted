package Games::Tournament;
$Games::Tournament::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:32
# $Id: $

use warnings;
use strict;
use Carp;

use List::Util qw/first/;
use List::MoreUtils qw/any all/;
use Scalar::Util qw/looks_like_number/;
use Scalar::Util qw/looks_like_number/;

use Games::Tournament::Swiss::Config;
use constant ROLES => @Games::Tournament::Swiss::Config::roles?
			@Games::Tournament::Swiss::Config::roles:
			Games::Tournament::Swiss::Config->roles;
use constant FIRSTROUND => $Games::Tournament::Swiss::Config::firstround;

=head1 NAME

Games::Tournament - Contestant Pairing 

=cut

=head1 SYNOPSIS

    $tourney = Games::Tournament->new(\@entrants);
    next if $capablanca->met($alekhine)

    $round = $tourney->meeting($member1, [$member2, $member3]);
    ...

=head1 DESCRIPTION

In a tournament, there are contestants, and matches over rounds between the contestants, in which they are differentiated by role. TODO firstround and roles.

=head1 METHODS

=head2 new

 Games::Tournament->new( rounds => 2, entrants => [ $a, $b, $c ] )

Creates a competition for entrants, over a number of rounds. entrants is a list of player objects. Enters (see enter method) each of the entrants in the tournament. (But why is the entrants arg being deleted?)

=cut 

sub new {
    my $self = shift;
    my %args = @_;
    my $entrants = $args{entrants};
    delete $args{entrants};
    my $object = bless \%args, $self;
    for my $entrant ( @$entrants ) { $object->enter( $entrant ); }
    return $object;
}


=head2 enter

 $tourney->enter($player)

Enters a Games::Tournament::Contestant player object with a rating, title id, and name in the entrants of the tournament. Die if no name or id. We are authoritarians. Warn if no rating defined. No check for duplicate ids. Set this round as their first round, unless they already entered in an earlier round (But did they play in that round?) Set their absent accessor if they are in absentees.

=cut

sub enter {
    my $self    = shift;
    my $player = shift;
    my $round = $self->round;
    die "Player " . $player->id . " entering in Round $round + 1?" unless
			looks_like_number($round);
    $player->firstround($round+1) unless $player->firstround;
    my $absent = $self->absentees;
    my @absentids;
    @absentids = map { $_->id } @$absent if $absent and ref $absent eq 'ARRAY';
    $player->absent(1) if any { $_ eq $player->id } @absentids;
    my $entrants = $self->entrants;
    for my $required ( qw/id name/ ) {
	unless ( $player->$required ) {
	    croak "No $required for player " . $player->id;
	}
    }
    for my $recommended ( qw/rating/ ) {
	unless ( defined $player->$recommended ) {
	    carp "No $recommended for player " . $player->id;
	    $player->$recommended( 'None' );
	}
    }
    push @$entrants, $player;
    $self->entrants( $entrants );
}

=head2 rank

 @rankings = $tourney->rank(@players)

Ranks a list of Games::Tournament::Contestant player objects by score, rating, title and name if they all have a score, otherwise ranks them by rating, title and name. This is the same ordering that is used to determine pairing numbers in a swiss tournament.

=cut

sub rank {
    my $self    = shift;
    my @players = @_;
    if ( all { defined $_->score } @players ) {
        sort {
                 $b->score <=> $a->score
              || $b->rating <=> $a->rating
              || $a->title cmp $b->title
              || $a->name cmp $b->name
        } @players;
    }
    else {
        sort {
                 $b->rating <=> $a->rating
              || $a->title cmp $b->title
              || $a->name cmp $b->name
        } @players;
    }
}

=head2 reverseRank

 @reverseRankings = $tourney->reverseRank(@players)

Ranks in reverse order a list of Games::Tournament::Contestant player objects by score, rating, title and name if they all have a score, otherwise reverseRanks them by rating, title and name.

=cut

sub reverseRank {
    my $self    = shift;
    my @players = @_;
    my @rankers = $self->rank(@players);
    return reverse @rankers;
}


#=head2 firstRound
#
#	$tourney->firstRound(7)
#
#Gets/sets the first round in the competition in which the swiss system is used to pair opponents, when this might not be the first round of the competition.
#
#=cut
#
#field 'firstRound' => 1;


=head2 named

    $tourney->named($name)

Returns a contestant whose name is $name, the first entrant with a name with stringwise equality. So beware same-named contestants.

=cut 

sub named {
    my $self        = shift;
    my $name        = shift;
    my $contestants = $self->entrants;
    return ( first { $_->name eq $name } @$contestants );
}


=head2 ided

    $tourney->ided($id)

Returns the contestant whose id is $id. Ids are grepped for stringwise equality.

=cut 

sub ided {
    my $self        = shift;
    my $id          = shift;
    my @contestants = @{ $self->entrants };
    return first { $_->id eq $id } @contestants;
}


=head2 roleCheck

    roleCheck(@games)

Returns the roles of the contestants in the individual $games in @games, eg qw/Black White/, qw/Home Away/, these being all the same (ie no typos), or dies.

=cut 

sub roleCheck {
    my $self  = shift;
    my @games = @_;
    my @roles;
    for my $game (@games) {
        my $contestants = $game->contestants;
        my $result      = $game->result;
        my @otherroles  = sort keys %$contestants;
        for my $key ( keys %$result ) {
            die "$key: $result->{$key}, but no $key player in $game."
              unless grep { $key eq $_ } @otherroles;
        }
        unless (@roles) {
            @roles = @otherroles;
        }
        else {
            my $test = 0;
            $test++ unless @roles == @otherroles;
            for my $i ( 0 .. $#roles ) {
                $test++ unless $roles[$i] eq $otherroles[$i];
            }
            die "@roles in game 1, but @otherroles in $game."
              if $test;
        }
    }
    return @roles;
}


=head2 met

	@rounds = $tourney->met($deepblue, @grandmasters)
	next if $tourney->met($deepblue, $capablanca)

In list context, returns an array of the rounds in which $deepblue met the corresponding member of @grandmasters (and of the empty string '' if they haven't met.) In scalar context, returns the number of grandmasters met. Don't forget to collect scorecards in the appropriate games first! (Assumes players do not meet more than once!) This is NOT the same as Games::Tournament::Contestant::met! See also Games;:Tournament::Swiss::whoPlayedWho.

=cut

sub met {
    my $self      = shift;
    my $player    = shift;
    my @opponents = @_;
    my @ids       = map { $_->id } @opponents;
    my $games     = $self->play;
    my $rounds    = $self->round;
    my %roundGames = map { $_ => $games->{$_} } FIRSTROUND .. $rounds;
    carp "No games to round $rounds. Where are the cards?" unless %roundGames;
    my @meetings;
    @meetings[ 0 .. $#opponents ] = ('') x @opponents;
    my $n = 0;
    for my $other (@opponents) {
        for my $round ( FIRSTROUND .. $rounds ) {
            my $game = $roundGames{$round}{ $other->id };
	    next unless $game and $game->can('contestants');
            $meetings[$n] = $round if $other->myOpponent($game) == $player;
        }
    }
    continue { $n++; }
    return @meetings if wantarray;
    return scalar grep { $_ } @meetings;
}


=head2 unmarkedCards

	@unfinished = $tourney->unmarkedCards(@games)

Returns an array of the games which have no or a wrong result. The result accessor should be an anonymous hash with roles, or 'Bye' as keys and either 'Win' & 'Loss', 'Loss' & 'Win' or 'Draw' & 'Draw', or 'Bye', as values.

=cut

sub unmarkedCards {
    my $self  = shift;
    my @games = @_;
    my @unfinished;
    for my $game (@games) {
        my $contestants = $game->contestants;
        my $result      = $game->result;
        push @unfinished, $game
          unless (
            ( keys %$contestants == 1 and $result->{Bye} =~ m/Bye/i )
            or $result->{ (ROLES)[0] } and $result->{ (ROLES)[1] }
            and (
                (
                        $result->{ (ROLES)[0] } eq 'Win'
                    and $result->{ (ROLES)[1] } eq 'Loss'
                )
                or (    $result->{ (ROLES)[0] } eq 'Loss'
                    and $result->{ (ROLES)[1] } eq 'Win' )
                or (    $result->{ (ROLES)[0] } eq 'Draw'
                    and $result->{ (ROLES)[1] } eq 'Draw' )
            )
          );
    }
    return @unfinished;
}


=head2 dupes

	$games = $tourney->dupes(@grandmasters)

Returns an anonymous array, of the games in which @grandmasters have met. Don't forget to collect scorecards in the appropriate games first! (Assumes players do not meet more than once!)

=cut

sub dupes {
    my $self    = shift;
    my @players = @_;
    my @ids     = map { $_->id } @players;
    my $games   = $self->play;
    my @dupes;
    map {
        my $id = $_;
        map { push @dupes, $games->{$id}->{$_} if exists $games->{$id}->{$_}; }
          @ids;
    } @ids;
    return \@dupes;
}


=head2 updateScores

 @scores = $tourney->updateScores;

Updates entrants' scores for the present (previous) round, using $tourney's play (ie games played) field. Returns an array of the scores in order of the player ids (not at the moment, it doesn't), dying on those entrants who don't have a result for the round. Be careful. Garbage in, garbage out. What is the present round?

=cut

sub updateScores {
    my $self    = shift;
    my $players = $self->entrants;
    my $round   = $self->round;
    my $games   = $self->play;
    my @scores;
    for my $player (@$players) {
        my $id     = $player->id;
        my $oldId  = $player->oldId;
        my $scores = $player->scores;
        my $card   = $games->{$round}->{$id};
        die "Game in round $round for player $id? Is $round the right round?"
          unless $card
          and $card->isa('Games::Tournament::Card');
        my $results = $card->{result};
        die @{ [ keys %$results ] } . " roles in player ${id}'s game?"
          unless grep { $_ eq (ROLES)[0] or $_ eq (ROLES)[1] or $_ eq 'Bye' }
          keys %$results;
        eval { $card->myResult($player) };
        die "$@: Result in player ${id}'s $card game in round $round?"
          if not $card or $@;
        my $result = $card->myResult($player);
        die "$result result in $card game for player $id in round $round?"
          unless $result =~ m/^(?:Win|Loss|Draw|Bye|Forfeit)/i;
        $$scores{$round} = $result;
        $player->scores($scores) if defined $scores;
        push @scores, $$scores{$round};
    }
    $self->entrants($players);
    # return @scores;
}


=head2 randomRole

 ( $myrole, $yourrole ) = randomRole;

This returns the 2 roles, @Games::Tournament::roles in a random order.

=cut

sub randomRole {
    my $self     = shift;
    my $evenRole = int rand(2) ? (ROLES)[0] : (ROLES)[1];
    my $oddRole  = $evenRole eq (ROLES)[0] ? (ROLES)[1] : (ROLES)[0];
    return ( $evenRole, $oddRole );
}


=head2 play

	$tourney->play

Gets the games played, keyed on round and id of player. Also sets, but you don't want to do that.

=cut

sub play {
    my $self = shift;
    my $play = shift;
    if ( defined $play ) { $self->{play} = $play; }
    elsif ( $self->{play} ) { return $self->{play}; }
}

=head2 entrants

	$tourney->entrants

Gets/sets the entrants as an anonymous array of player objects. Users may rely on the original order being maintained in web app cookies. 

=cut

sub entrants {
    my $self     = shift;
    my $entrants = shift;
    if ( defined $entrants ) { $self->{entrants} = $entrants; }
    elsif ( $self->{entrants} ) { return $self->{entrants}; }
}


=head2 absentees

	$tourney->absentees

Gets/sets the absentees as an anonymous array of player objects. These players won't be included in the brackets of players who are to be paired.

=cut

sub absentees {
    my $self     = shift;
    my $absentees = shift;
    if ( defined $absentees ) { $self->{absentees} = $absentees; }
    elsif ( $self->{absentees} ) { return $self->{absentees}; }
}


=head2 round

	$tourney->round

Gets/sets the round number of a round near you. The default round number is 0. That is, the 'round' before round 1. The question is when one round becomes the next round.

=cut

sub round {
    my $self  = shift;
    my $round = shift;
    if ( defined $round ) { $self->{round} = $round; }
    elsif ( $self->{round} ) { return $self->{round}; }
    else { return 0 }
}


=head2 rounds

	$tourney->rounds

Gets/sets the number of rounds in the tournament.

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


=head2 idNameCheck

$tourney->idNameCheck # WARNING: 13301616 and 13300849 both, Petrosian, Tigran

Dies if 2 entrants have the same id, warns if they have the same name.

=cut

sub idNameCheck {
    my $self = shift;
    my $lineup = $self->entrants;
    my (%idcheck, %namecheck);
    for my $player ( @$lineup ) {
	my $id = $player->id;
	my $name = $player->name;
	if ( defined $idcheck{$id} ) {
	    croak $name . " and $idcheck{$id} have the same id: $id";
	}
	if ( defined $namecheck{$name} ) {
	    carp "WARNING: $id and $namecheck{$name} have the same name: " .
		$name . ". Proceeding, but BEWARE there may be problems later,";
	}
	$idcheck{$id} = $name;
	$namecheck{$name} = $id;
    }
}


=head2 idCheck

$tourney->idCheck # Petrosian, Tigran, and Tigran Petrosian both 13301616

Dies if 2 entrants have the same id

=cut

sub idCheck {
    my $self = shift;
    my $lineup = $self->entrants;
    my %idcheck;
    for my $player ( @$lineup ) {
	my $id = $player->id;
	my $name = $player->name;
	if ( defined $idcheck{$id} ) {
	    croak $name . " and $idcheck{$id} have the same id: $id";
	}
	$idcheck{$id} = $name;
    }
}

=head2 nameCheck

$tourney->idNameCheck # WARNING: 13301616 and 13300849 both, Petrosian, Tigran

Warn if 2 entrants have the same name

=cut

sub nameCheck {
    my $self = shift;
    my $lineup = $self->entrants;
    my %namecheck;
    for my $player ( @$lineup ) {
	my $id = $player->id;
	my $name = $player->name;
	if ( defined $namecheck{$name} ) {
	    carp "WARNING: $id and $namecheck{$name} have the same name: " .
		$name . ". Proceeding, but BEWARE there may be problems later,";
	}
	$namecheck{$name} = $id;
    }
}

=head2 odd

 float($lowest) if $self->odd(@group)

Tests whether the number of players in @group is odd or not.

=cut

sub odd {
    my $self = shift;
    my @n    = @_;
    return @n % 2;
}


=head2 clearLog

	$pairing->clearLog(qw/C10 C11/)

Discards the logged messages for the passed procedures.

=cut

sub clearLog {
    my $self = shift;
    my @states = @_;
    my $log = $self->{log};
    delete $log->{$_} for @states;
    return;
}


=head2 catLog

	$pairing->catLog(qw/C10 C11/)

Returns the messages logged for the passed procedures, or all logged procedures if no procedures are passed, as a hash keyed on the procedures. If no messages were logged, because the procedures were not loggedProcedures, no messages will be returned.

=cut

sub catLog {
    my $self = shift;
    my @states = @_;
    @states = $self->loggedProcedures unless @states;
    my $log = $self->{log};
    my %report;
    for my $state ( @states ) {
	my $strings = $log->{$state}->{strings};
	unless ( $strings and ref $strings eq 'ARRAY' ) {
	    $report{$state} = undef;
	    next;
	}
	$report{$state} = join '', @$strings;
    }
    return %report;
}


=head2 tailLog

	$pairing->tailLog(qw/C10 C11/)

Returns the new messages logged for the passed procedures since they were last tailed, as a hash keyed on the procedures. If no messages were logged, because the procedures were not loggedProcedures, no messages will be returned.

=cut

sub tailLog {
    my $self = shift;
    my @states = @_;
    @states = $self->loggedProcedures unless @states;
    my $log = $self->{log};
    my %report = map { $_ => $log->{$_}->{strings} } @states;
    my %tailpos = map { $_ => $log->{$_}->{tailpos} } @states;
    my (%newpos, %lastpos, %tailedReport);
    for my $state ( @states )
    {
	if ( defined $tailpos{$state} )
	{
	    $newpos{$state} = $tailpos{$state} + 1;
	    $lastpos{$state} = $#{ $report{$state} };
	    $tailedReport{$state} = join '',
		@{$report{$state}}[ $newpos{$state}..$lastpos{$state} ];
	    $log->{$_}->{tailpos} = $lastpos{$_} for @states;
	}
	elsif ( $report{$state} ) {
	    $newpos{$state} = 0;
	    $lastpos{$state} = $#{ $report{$state} };
	    $tailedReport{$state} = join '',
		@{$report{$state}}[ $newpos{$state}..$lastpos{$state} ];
	    $log->{$_}->{tailpos} = $lastpos{$_} for @states;
	}
    }
    return %tailedReport;
}


=head2 log

	$pairing->log('x=p=1, no more x increases in Bracket 4 (2).')

Saves the message in a log iff this procedure is logged.

=cut

sub log {
    my $self = shift;
    my $message = shift;
    return unless $message;
    (my $method = uc((caller 1)[3])) =~ s/^.*::(\w+)$/$1/;
    my @loggable = $self->loggedProcedures;
    push @{ $self->{log}->{$method}->{strings} }, "\t$message\n" if
		    any { $_ eq $method } @loggable;
    return;
}


=head2 loggedProcedures

	$group->loggedProcedures(qw/C10 C11 C12/)
	$group->loggedProcedures(qw/C5 C6PAIRS C7 C8/)

Adds messages generated in the procedures named in the argument list to a reportable log. Without an argument returns the logged procedures as an array.

=cut

sub loggedProcedures {
    my $self = shift;
    my @states = @_;
    unless ( @states ) { return keys %{ $self->{logged} }; }
    my %logged;
    @logged{qw/START NEXT PREV C1 C2 C3 C4 C5 C6PAIRS C6OTHERS C7 C8 C9 C10 C11 C12 C13 C14 BYE MATCHPLAYERS ASSIGNPAIRINGNUMBERS/} = (1) x 21;
    for my $state (@states)
    {   
	carp "$state is unloggable procedure" if not exists $logged{$state};
	$self->{logged}->{$state} = 1;
	# push @{ $self->{log}->{$state}->{strings} }, $state . ",";
    }
    return;
}


=head2 loggingAll

	$group->loggingAll

Adds messages generated in all the procedures to a reportable log

=cut

sub loggingAll {
    my $self = shift;
    my %logged;
    @logged{qw/START NEXT PREV C1 C2 C3 C4 C5 C6PAIRS C6OTHERS C7 C8 C9 C10 C11 C12 C13 C14 BYE MATCHPLAYERS ASSIGNPAIRINGNUMBERS/} = (1) x 21;
    for my $state ( keys %logged )
    {   
	# carp "$state is unloggable procedure" if not exists $logged{$state};
	$self->{logged}->{$state} = 1;
    }
    return;
}


=head2 disloggedProcedures

	$group->disloggedProcedures
	$group->disloggedProcedures(qw/C6PAIRS C7 C8/)

Stops messages generated in the procedures named in the argument list being added to a reportable log. Without an argument stops logging of all procedures.

=cut

sub disloggedProcedures {
    my $self = shift;
    my @states = @_;
    unless ( @states )
    {
	my @methods = keys %{ $self->{logged} };
	@{$self->{logged}}{@methods} = (0) x @methods;
    }
    my %logged;
    @logged{qw/START NEXT PREV C1 C2 C3 C4 C5 C6PAIRS C6OTHERS C7 C8 C9 C10 C11 C12 C13 C14 BYE MATCHPLAYERS ASSIGNPAIRINGNUMBERS/} = (1) x 21;
    for my $state (@states)
    {   
	carp "$state is unloggable procedure" if not defined $logged{$state};
	$self->{logged}->{$state} = 0;
    }
    return;
}


=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-swiss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament

# vim: set ts=8 sts=4 sw=4 noet:
