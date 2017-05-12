package Games::Tournament::Swiss::Bracket;
$Games::Tournament::Swiss::Bracket::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:55
# $Id: $

use warnings;
use strict;
use Carp;

use constant ROLES => @Games::Tournament::Swiss::Config::roles;

use base qw/Games::Tournament::Swiss/;
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Card;
use List::Util qw/max min reduce sum/;
use List::MoreUtils qw/any notall/;

=head1 NAME

Games::Tournament::Swiss::Bracket - Players with same/similar scores pairable with each other

=cut

=head1 SYNOPSIS

    $tourney = Games::Tournament::Swiss>new($rounds, \@entrants);
    @rankedPlayers = $tourney->assignPairingNumbers;
    @firstbrackets = $t->formBrackets;
    ...
    $tourney->collectCards(@games);
    @scores = $tourney->updateScores($round);
    @groups = $tourney->formBrackets;

=head1 DESCRIPTION

In a Swiss tournament, in each round contestants are paired with other players with the same, or similar, scores. These contestants are grouped into a score group (bracket) in the process of deciding who plays who.

The concept of immigration control is applied to impose order on the players floating in and out of these score brackets. That is, floating is like flying.
I pulled back on this metaphor. It was probably overengineering.

=head1 METHODS

=head2 new

 $group = Games::Tournament::Swiss::Bracket->new( score => 7.5, members => [ $a, $b, $c ], remainderof => $largergroup )

members is a reference to a list of Games::Tournament::Contestant::Swiss objects. The order is important. If the score group includes floaters, these members' scores will not be the same as $group->score. Such a heterogenous group is paired in two parts--first the downfloaters, and then the homogeneous remainder group. Remainder groups can be recognized by the existence of a 'remainderof' key that links them to the group they came from. Some members may also float down from a remainder group. Each bracket needs a score to determine the right order they will be paired in. The number, from 1 to the total number of brackets, reflects that order. A3

=cut 

sub new {
    my $self = shift;
    my %args = @_;
    my $score = $args{score};
    die "Bracket has score of: $score?" unless defined $score;
    bless \%args, $self;
    $args{floatCheck} = "None";
    return \%args;
}


=head2 natives

 @floaters = $group->natives

Returns those members who were in this bracket originally, as that was their birthright, their scores being all the same. One is a native of only one bracket, and you cannot change this status except XXX EVEN by naturalization.

=cut

sub natives {
    my $self = shift;
    return () unless @{ $self->members };
    my $members    = $self->members;
    my $foreigners = $self->immigrants;
    my @natives    = grep {
        my $member = $_->pairingNumber;
        not grep { $member == $_->pairingNumber } @$foreigners
	    } @$members;
    return \@natives;
}


=head2 citizens

 @floaters = $group->citizens

Returns those members who belong to this bracket. These members don't include those have just floated in, even though this floating status may be permanent. One is a citizen of only one bracket, and you cannot change this status except by naturalization.

=cut

sub citizens {
    my $self = shift;
    return () unless @{ $self->members };
    my $members    = $self->members;
    my $foreigners = $self->immigrants;
    my @natives    = grep {
        my $member = $_->pairingNumber;
        not grep { $member == $_->pairingNumber } @$foreigners
    } @$members;
    return \@natives;
}


=head2 naturalize

 $citizen = $group->naturalize($foreigner)

Gives members who are resident, but not citizens, ie immigrants, having been floated here from other brackets, the same status as natives, making them indistinguishable from them. This will fail if the player is not resident or not an immigrant. Returns the player with their new status.

=cut

sub naturalize {
    my $self      = shift;
    my $foreigner = shift;
    my $members   = $self->residents;
    return unless any
	{ $_->pairingNumber == $foreigner->pairingNumber } @$members;
    my $direction = $foreigner->floating;
    return unless $direction eq 'Up' or $direction eq 'Down';
    $foreigner->floating('');
    return $foreigner;
}


=head2 immigrants

 @floaters = @{$group->immigrants}

Returns those members who are foreigners, having been floated here from other brackets. At any one point a player may or may not be a foreigner. But if they are, they only can be a foreigner in one bracket. 

=cut

sub immigrants {
    my $self = shift;
    return () unless @{ $self->members };
    my $members = $self->residents;
    my @immigrants = grep { $_->floating } @$members;
    return \@immigrants;
}


=head2 downFloaters

 @floaters = $group->downFloaters

Returns those members downfloated here from higher brackets.

=cut

sub downFloaters {
    my $self = shift;
    my $members = $self->members;
    return () unless @$members and $self->trueHetero;
    my %members;
    for my $member ( @$members )
    {
	my $score = defined $member->score? $member->score: 0;
	push @{$members{$score}}, $member;
    }
    my $min = min keys %members;
    delete $members{$min};
    my @floaters = map { @$_ } values %members;
    return @floaters;
}


=head2 upFloaters

 @s1 = $group->upFloaters

Returns those members upfloated from the next bracket.

=cut

sub upFloaters {
    my $self = shift;
    return () unless @{ $self->members };
    my @members = $self->residents;
    grep { $_->floating and $_->floating =~ m/^Up/i } @{ $self->members };
}


=head2 residents

	$pairables = $bracket->residents

Returns the members includeable in pairing procedures for this bracket because they haven't been floated out, or because they have been floated in. That is, they are not an emigrant. At any one point, a player is resident in one and only one bracket, unless they are in transit. At some other point, they may be a resident of another bracket.

=cut

sub residents {
    my $self    = shift;
    my $members = $self->members;
    my @residents;
    my $floated = $self->emigrants;
    for my $member (@$members) {
        push @residents, $member
          unless any { $member->pairingNumber == $_->pairingNumber } @$floated;
    }
    return \@residents;
}


=head2 emigrants

	$bracket->emigrants($member)
	$gone = $bracket->emigrants

Sets whether this citizen will not be included in pairing of this bracket. That is whether they have been floated to another bracket for pairing there. Gets all such members. A player may or may not be an emigrant. They can only stop being an emigrant if they move back to their native bracket. To do this, they have to be processed by 'entry'.

=cut

sub emigrants {
    my $self    = shift;
    my $floater = shift;
    if ($floater) { push @{ $self->{gone} }, $floater; }
    else { return $self->{gone}; }
}


=head2 exit

	$bracket->exit($player)

Removes $player from the list of members of the bracket. They are now in the air. So make sure they enter another bracket.

=cut

sub exit {
    my $self       = shift;
    my $members    = $self->members;
    my $exiter     = shift;
    my $myId = $exiter->pairingNumber;
    my @stayers = grep { $_->pairingNumber != $myId } @$members;
    my $number = $self->number;
    croak "Player $myId did not exit Bracket $number" if @stayers == @$members;
    $self->members(\@stayers);
    #my $immigrants = $self->immigrants;
    #if ( grep { $_ == $member } @$immigrants ) {
    #    @{ $self->members } = grep { $_ != $member } @$members;
    #}
    #else {
    #    $self->emigrants($member);
    #}
    return;
}


=head2 entry

	$bracket->entry($native)
	$bracket->entry($foreigner)

Registers $foreigner as a resident (and was removing $native from the list of emigrants of this bracket, because they have returned from another bracket as in C12, 13).

=cut

sub entry {
    my $self   = shift;
    my $members = $self->residents;
    my $enterer = shift;
    my $myId = $enterer->id;
    my $number = $self->number;
    croak "Player $myId cannot enter Bracket $number. Is already there." if 
	any { $_->{id} eq $myId } @$members;
    unshift @$members, $enterer;
    $self->members(\@$members);
    return;
}


=head2 reentry

	$bracket->reentry($member)

Removes this native (presumably) member from the list of emigrants of this bracket, because they have returned from another bracket as in C12, 13. Returns undef, if $member wasn't an emigrant. Otherwise returns the updated list of emigrants.

=cut

sub reentry {
    my $self      = shift;
    my $returnee  = shift;
    my $emigrants = $self->emigrants;
    if ( any { $_->pairingNumber == $returnee->pairingNumber } @$emigrants ) {
        my @nonreturnees = grep {
	    $_->pairingNumber != $returnee->pairingNumber } @$emigrants;
	# @{ $self->{gone} } = @nonreturnees;
        $self->{gone} = \@nonreturnees;
        return @nonreturnees;
    }
    #my @updatedlist = grep { $_->id != $returnee->id } @$emigrants;
    #$self->emigrants($_) for @updatedlist;
    #return @updatedlist if grep { $_->id == $returnee->id } @$emigrants;
    return;

}


=head2 dissolved

 $group->dissolved(1)
 $s1 = $group->s1($players)
 $s1 = $group->s1

Dissolve a bracket, so it is no longer independent, its affairs being controlled by some other group:

=cut

sub dissolved {
    my $self = shift;
    my $flag   = shift;
    if ( defined $flag )
    {
	$self->{dissolved} = $flag;
	return $flag? 1: 0;
    }
    else {
	return $self->{dissolved}? 1: 0;
    }
}


=head2 s1

 $group->s1
 $s1 = $group->s1($players)
 $s1 = $group->s1

Getter/setter of the p players in the top half of a homogeneous bracket, or the p downFloaters in a heterogeneous bracket, as an array. A6

=cut

sub s1 {
    my $self = shift;
    my $s1   = shift;
    if ( defined $s1 ) {
        $self->{s1} = $s1;
        return $s1;
    }
    elsif ( $self->{s1} ) { return $self->{s1}; }
    else { $self->resetS12; return $self->{s1}; }
}


=head2 s2

 $s2 = $group->s2

Getter/Setter of the players in a homogeneous or a heterogeneous bracket who aren't in S1. A6

=cut

sub s2 {
    my $self = shift;
    my $s2   = shift;
    if ( defined $s2 ) {
        $self->{s2} = $s2;
        return $s2;
    }
    elsif ( $self->{s2} ) { return $self->{s2}; }
    else { $self->resetS12; return $self->{s2}; }
}


=head2 resetS12

 $group->resetS12

Resetter of S1 and S2 to the original members, ranked before exchanges in C8. A6

=cut

sub resetS12 {
    my $self    = shift;
    my $number = $self->number;
    my $members = $self->residents;
    return [] unless $#$members >= 1;
    my (@s1, @s2);
    use Games::Tournament;
    if ( $self->hetero ) {
	my %scorers;
	for my $member (@$members)
	{
	    my $score = defined $member->score? $member->score: 0;
	    push @{ $scorers{$score} }, $member;
	}
	my @scores = reverse sort { $a <=> $b } keys %scorers;
	#carp @scores . " different scores in Hetero Bracket $number"
	#	if @scores > 2;
        @s2 = @{$scorers{$scores[-1]}};
	my %s2 = map { $_->pairingNumber => $_ } @s2;
	@s1 = grep { not exists $s2{$_->pairingNumber} } $self->rank(@$members);
    }
    else {
        my $p       = $self->p;
        @s1 = ( $self->rank(@$members) )[ 0 .. $p - 1 ];
        @s2 = ( $self->rank(@$members) )[ $p .. $#$members ];
    }
    $self->s1(\@s1);
    $self->s2(\@s2);
    my @lastS2ids = reverse map { $_->pairingNumber } @s2;
    $self->{lastS2ids} = \@lastS2ids;
    die "undef player in Bracket $number S1, S2" if any { not defined } @s1, @s2;
    return;
}


=head2 resetShuffler

    $previous->entry($_) for @returnees;
    $previous->resetShuffler;
    return C7;

Take precautions to prevent transposing players who are no longer in the bracket in S2, or to make sure they ARE transposed, when finding a different pairing, before returning from C10,12,13 (C11?). Do this by resetting S1 and S2. Don't use this in the wrong place. We don't want to try the same pairing twice.

=cut 

sub resetShuffler {
    my $self   = shift;
    my $members = $self->members;
    my $s1      = $self->s1;
    my $s2      = $self->s2;
    my %s1 = map { $_->pairingNumber => $_ } @$s1;
    my %s2 = map { $_->pairingNumber => $_ } @$s2;
    my %members = map { $_->pairingNumber => $_ } @$members;
    # my %tally; @tally{keys %members} = (0) x keys %members;
    my $memberChangeTest = ( (notall { exists $members{$_} } keys %s1) or
    (notall { exists $members{$_} } keys %s2) or (@$s1 + @$s2 != @$members));
    $self->resetS12 if $memberChangeTest;
}


=head2 p

 $tables = $group->p

Half the number of players in a homogeneous bracket, rounded down to the next lowest integer. Or the number of down floaters in a heterogeneous bracket. Also the number of players in S1, and thus the number of pairings in the pair group. If there are more downfloaters than original members, half the number of players. (See A1,2)A6

=cut

sub p {
    my $self    = shift;
    my $members = $self->members;
    my $n = @$members;
    return 0 unless $n >= 2;
    my $p;
    if ( $self->hetero ) {
	my %scorers;
	for my $member ( @$members ) {
	    my $score = defined $member->score? $member->score: 0;
	    $scorers{$score}++;
	}
	my $lowestScore = min keys %scorers;
	return unless defined $lowestScore;
	$p = $n - $scorers{$lowestScore};
        $p = int( $n / 2 ) if $p > $n/2;
    }
    else {
        $p = int( $n / 2 );
    }
    return $p;
}


=head2 bigGroupP

 $tables = $group->bigGroupP

Half the number of players in a big bracket (group), rounded down to the next lowest integer. Sometimes the number of pairs in a combined bracket, particularly, a heterogeneous bracket and its remainder group is needed. In such cases, p will be just the number of downfloated players, which is not what we want. In a non-heterogeneous bracket, bigGroupP will be the same as p. See C11

=cut

sub bigGroupP {
    my $self    = shift;
    my $members = $self->members;
    my $n = @$members;
    if ( $self->{remainderof} )
    {
	my $remaindered = $self->{remainderof}->members;
	$n += @$remaindered;
    }
    elsif ( $self->{remaindered} ) {
	my $heteroMembers = $self->{remainder}->members;
	$n += @$heteroMembers;
    }
    return 0 unless $n >= 2;
    my $p = int( $n / 2 );
    return $p;
}


=head2 pprime

 $tables = $group->pprime

p is half the number of players in a bracket, but we may have to accept fewer pairings than this number if suitable opponents cannot be found for players, up to the point where p=0. pprime sets/gets this real p number. A8

=cut

sub pprime {
    my ( $self, $p ) = @_;
    my $pprime = $self->{pprime};
    if ( defined $p ) { $self->{pprime} = $p; }
    elsif ( defined $pprime ) { return $pprime; }
    else {
        $self->{pprime} = $self->p;
        return $self->{pprime};
    }
}


=head2 bigGroupPprime

 $tables = $group->bigGroupPprime

bigGroupP is half the number of players in a heterogeneous bracket and its remainder group, but we may have to accept fewer pairings than this number if suitable opponents cannot be found for players, up to the point where no players are paired. bigGroupPprime sets/gets this real p number for the combined groups/brackets. A8

=cut

sub bigGroupPprime {
    my ( $self, $p ) = @_;
    my $bigGroupPprime = $self->{biggrouppprime};
    if ( defined $p ) {
	$self->{biggrouppprime} = $p;
	if ( $self->{remainderof} ) {
	    $self->{remainderof}->{biggrouppprime} = $p;
	}
	elsif ( $self->{remainder} ) {
	    $self->{remainder}->{biggrouppprime} = $p;
	}
	return;
    }
    elsif ( defined $bigGroupPprime ) { return $bigGroupPprime; }
    else {
	$self->{biggrouppprime} = $self->bigGroupP;
        return $self->{biggrouppprime};
    }
}


=head2 q

 $tables = $group->q

Number of players in the score bracket divided by 2 and then rounded up. In a homogeneous group with an even number of players, this is the same as p. A8

=cut

sub q {
    my $self    = shift;
    my $players = $self->members;
    my $q = @$players % 2 ? ( $#$players + 2 ) / 2 : ( $#$players + 1 ) / 2;
}


=head2 x

 $tables = $group->x

Sets the number, ranging from zero to p, of matches in the score bracket in which players will have their preferences unsatisfied. A8

=cut

sub x {
    my $self    = shift;
    my $players = $self->residents;
    my $numbers = sub {
	my $n = shift;
	return scalar grep {
	    $_->preference->role and $_->preference->role eq (ROLES)[$n] }
	    @$players;
    };
    my $w = $numbers->(0);
    my $b = $numbers->(1);
    my $q = $self->q;
    my $x = $w >= $b ? $w - $q : $b - $q;
    $self->{x} = $x < 0? 0: $x;
}


=head2 bigGroupX

 $tables = $group->bigGroupX

x is okay for a homogeneous group, uncombined with other groups, but in the case of groups that are interacting to form joined brackets, or in that of a heterogeneous bracket and a remainder group, we need a bigGroupX to tell us how many matches in the total number, ranging from zero to bigGroupP, of matches in the score bracket(s) will have players with unsatisfied preferences. A8

=cut

sub bigGroupX {
    my $self    = shift;
    my $players = $self->members;
    my $w       =
      grep { $_->preference->role and $_->preference->role eq (ROLES)[0] }
      @$players;
    my $b = @$players - $w;
    my $q = $self->q;
    my $x = $w >= $b ? $w - $q : $b - $q;
    my $bigGroupX = $x;
    if ( $self->{remainderof} ) { $bigGroupX += $self->{remainderof}->x; }
    elsif ( $self->{remainder} ) { $bigGroupX += $self->{remainder}->x; }
    $self->{biggroupx} = $bigGroupX;
    return $self->{biggroupx};
}


=head2 bigGroupXprime

 $tables = $group->bigGroupXprime

xprime is a revised upper limit on matches where preferences are not satisfied, but in the case of a combined bracket (in particular, a heterogeneous bracket and a remainder group) we need a figure for the total number of preference-violating matches over the 2 sections, because the distribution of such matches may change. bigGroupXprime sets/gets this total x number. A8

=cut

sub bigGroupXprime {
    my $self   = shift;
    my $x      = shift;
    my $xprime = $self->{biggroupxprime};
    if ( defined $x ) {
	$self->{biggroupxprime} = $x;
	if ( $self->{remainderof} ) {
	    $self->{remainderof}->{biggroupxprime} = $x;
	}
	elsif ( $self->{remainder} ) {
	    $self->{remainder}->{biggroupxprime} = $x
	}
	return; }
    elsif ( defined $xprime ) { return $xprime; }
    else {
	if ( $self->{remainderof} ) {
	    my $x = $self->{remainderof}->{biggroupxprime};
	    return $x if defined $x;
	}
	elsif ( $self->{remainder} ) {
	     $x = $self->{remainder}->{biggroupxprime};
	    return $x if defined $x;
	}
	else { return $self->bigGroupX; }
    }
}


=head2 xprime

 $tables = $group->xprime

x is the lower limit on matches where preferences are not satisfied, but the number of such undesirable matches may be increased if suitable opponents cannot be found for players, up to the point where only players with Absolute preferences have their preferences satisfied. xprime sets/gets this real x number. A8

=cut

sub xprime {
    my $self   = shift;
    my $x      = shift;
    my $xprime = $self->{xprime};
    if ( defined $x ) { $self->{xprime} = $x; return; }
    elsif ( defined $xprime ) { return $xprime; }
    else {
        $self->{xprime} = $self->x;
        return $self->{xprime};
    }
}


=head2 floatCheckWaive

 $tables = $group->floatCheckWaive

There is an ordered sequence in which the checks of compliance with the Relative Criteria B5,6 restriction on recurring floats are relaxed in C9,10. The order is 1. downfloats for players downfloated 2 rounds before, 2. downfloats for players downfloated in the previous round (in C9), 3. upfloats for players floated up 2 rounds before, 4. upfloats for players floated up in the previous round (for players paired with opponents from a higher bracket in a heterogeneous bracket, in C10). (It appears levels are being skipped, eg from B6Down to B6Up or from All to B6Down.) Finally, although it is not explicitly stated, all float checks must be dropped and pairings considered again, before reducing the number of pairs made in the bracket. (This is not entirely correct.) This method sets/gets the float check waive level at the moment. All criteria below that level should be checked for compliance. The possible values in order are 'None', 'B6Down', 'B5Down', 'B6Up', 'B5Up', 'All'. TODO Should there be some way of not requiring the caller to know how to use this method and what the levels are.

=cut

sub floatCheckWaive {
    my $self   = shift;
    my $number = $self->number;
    my $level      = shift;
    warn "Unknown float level: $level" if
	$level and $level !~ m/^(?:None|B6Down|B5Down|B6Up|B5Up|All)$/i;
    my $oldLevel = $self->{floatCheck};
    if ( defined $level ) {
	warn 
"Bracket [$number]'s old float check waive level, $oldLevel is now $level."
	    unless $level eq 'None' or
	    $oldLevel eq 'None' and $level eq 'B6Down' or
	    $oldLevel eq 'B6Down' and $level eq 'B5Down' or
	    $oldLevel eq 'B6Down' and $level eq 'B6Up' or
	    $oldLevel eq 'B5Down' and $level eq 'B6Up' or 
	    $oldLevel eq 'B6Up' and $level eq 'B5Up' or
	    $oldLevel eq 'B5Up' and $level eq 'All' or
	    # $oldLevel eq 'B5Down' and $level eq 'All' or
	    $oldLevel eq 'All' and $level eq 'None' or
	    $oldLevel eq 'All' and $level eq 'B6Down';
	$self->{floatCheck} = $level;
    }
    elsif ( defined $self->{floatCheck} ) { return $self->{floatCheck}; }
    else { return; }
}


=head2 hetero

	$group->hetero

Gets (but doesn't set) whether this group is heterogeneous, ie includes players who have been downfloated from a higher score group, or upfloated from a lower score group, or if it is homogeneous, ie every player has the same score. A group where half or more of the members have come from a higher bracket is regarded as homogeneous. We use the scores of the players, rather than a floating flag.

=cut

sub hetero {
    my $self = shift;
    my @members = @{$self->members};
    my %tally;
    for my $member ( @members ) {
	my $score = defined $member->score? $member->score: 0;
	$tally{$score}++ ;
    }
    my @range = keys %tally;
    return 0 if @range == 1;
    my $min = min @range;
    return unless defined $min;
    return 0 if $tally{$min} <= @members/2;
    return 1 if $tally{$min} > @members/2;
    return;
}


=head2 trueHetero

	$group->trueHetero

Gets whether this group is really heterogeneous, ie includes players with different scores, because they been downfloated from a higher score group, or upfloated from a lower score group, even if it is being treated as homogeneous. A group where half or more of the members have come from a higher bracket is regarded as homogeneous, but it is really heterogeneous.

=cut

sub trueHetero {
    my $self = shift;
    my @members = @{$self->members};
    my %tally;
    for my $member ( @members ) {
	my $score = defined $member->score? $member->score: 0;
	$tally{$score}++;
    }
    my @range = keys %tally;
    return unless @range;
    return 0 if @range == 1;
    return 1;
}


=head2 c7shuffler

	$nextS2 = $bracket->c7shuffler($firstmismatch)
	if ( @nextS2 compatible )
	{
	    create match cards;
	}

Gets the next permutation of the second-half players in D1 transposition counting order, as used in C7, that will not have the same incompatible player in the bad position found in the present transposition. If you get an illegal modulus error, check your $firstmismatch is a possible value.

=cut

sub c7shuffler {
    my $self     = shift;
    my $position = shift;
    my $bigLastGroup = shift;
    my $s2       = $self->s2;
    die "C7 shuffle: pos $position past end of S2" if $position > $#$s2;
    my @players  = $self->rank(@$s2);
    @players  = $self->reverseRank(@$s2) if $bigLastGroup;
    # my @players  = @$s2;
    my $p        = $self->p;
    my @pattern;
    my @copy = @players;
    for my $i ( 0 .. $#$s2 ) {
        my $j = 0;
        $j++ until $s2->[$i]->pairingNumber == $copy[$j]->pairingNumber;
        $pattern[$i] = $j;
        splice @copy, $j, 1;
    }
    my $value = $pattern[$position];
    my @nextPattern;
    @nextPattern[ 0 .. $position ] = @pattern[ 0 .. $position ];
    @nextPattern[ $position + 1 .. $#pattern ] =
      (0) x ( $#pattern - $position );
    for my $digit ( reverse( 0 .. $position ) ) {
	die "${digit}th digit overrun of @pattern \@pattern" if
						    @pattern == $digit;
        $nextPattern[$digit] = ++$value % ( @pattern - $digit );
        last unless $nextPattern[$digit] == 0;
    }
    continue { $value = $pattern[ $digit - 1 ]; }
    return unless grep { $_ } @nextPattern;
    my @permutation;
    for my $pos (@nextPattern) {
        push @permutation, splice( @players, $pos, 1 );
    }
    return @permutation;

 #my @selectS2 = $group->c7shuffler($badpair);
 #my @unselectS2  = @$s2;
 #for my $position ( 0 .. $#$s2 )
 #{
 #    my $player = $s2->[$#$s2 - $position];
 #    splice @unselectS2, $#$s2 - $position, 1 if grep{$_ eq $player} @selectS2;
 #}
 #my @newS2 = (@selectS2, @unselectS2);
}


=head2 c7iterator

	$next = $bracket->c7iterator
	while ( my @s2 = &$next )
	{
	    create match cards unless this permutation is incompatible;
	}

DEPRECATED Creates an iterator for the permutation of the second-half players in D1 transposition counting order, as used in C7. Only as many players as are in S1 can be matched, so we get only the permutations of all the p-length combinations of members of S2. Deprecated because if C1 or C6 finds a player in a certain position in S2 should not be paired with the player in the corresponding position in S1, we need to be able to skip ahead to the next permutation where a different player is in that position.

=cut 

sub c7iterator {
    my $self    = shift;
    my $players = $self->s2;
    my $p       = $self->p;
    my $n       = 0;
    return sub {
        my @pattern = n_to_pat->( $n, $#$players + 1, $p );
        my @result = permGenerator->( \@pattern, $players );
        print "transposition $n:\t";
        $n++;
        return @result;
    };
    my $permGenerator = sub {
        my $pattern = shift;
        my @items   = @{ shift() };
        my @r;
        for my $pos (@$pattern) {
            push @r, splice( @items, $pos, 1 );
        }
        return @r;
    };
    my $n_to_pat = sub {
        my @odometer;
        my ( $n, $length, $k ) = @_;
        for my $i ( $length - $k + 1 .. $length ) {
            unshift @odometer, $n % $i;
            $n = int( $n / $i );
        }
        return $n ? () : @odometer;
    };
}


=head2 c8iterator

	$next = $bracket->c8iterator
	while ( my @members = &$next )
	{
	    next if grep {$incompat{$s1[$_]}{$s2[$_]}} 0..$p-1);
	}

Creates an iterator for the exchange of @s1 and @s2 players in D2 order, as used in C8. Exchanges are performed in order of the difference between the pairing numbers of the players exchanged. If the difference is equal, the exchange with the lowest player is to be performed first. XXX Only as many players as in S1 can be matched, so does this mean some exchanges don't have an effect? I don't understand the description when there are an odd number of players. There appears to be a bug with only 3 players. 1 and 2 should be swapped, I think. I think the order of exchanges of 2 players each may also have some small inconsistencies with the FIDE order.

=cut 

sub c8iterator {
    my $self      = shift;
    my $letter         = 'a';
    my $p         = $self->p;
    my $oddBracket = @{$self->members} % 2;
    my @exchanges;
    unless ($oddBracket)
    {
	@exchanges = map {
	    my $i = $_;
	    map { [ [ $_, $_+$i ] ] }
	      reverse( ( max 1, $p-$i ) .. ( min $p-1, 2*($p-1)-$i ) )
	} ( 1 .. 2*($p-1)-1 );
    }
    elsif ( $oddBracket ) {
	my $pPlus = $p+1;
	@exchanges = map {
	    my $i = $_;
	    map { [ [ $_-1, $_+$i-1 ] ] }
	      reverse( (max 1, $pPlus-$i) .. (min $pPlus-1, 2*($pPlus-1)-$i) )
	} ( 1 .. 2*($pPlus-1)-1 );
    }
    my @exchanges2;
    unless ($oddBracket)
    {
	my @s1pair = map {
	    my $i = $_;
	    map { [ $i - $_, $i ] } 1 .. $i - 1
	} reverse 2 .. $p - 1;
	my @s2pair = map {
	    my $i = $_;
	    map { [ $i, $i + $_ ] } 1 .. 2 * ( $p - 1 ) - $i
	} $p .. 2 * ( $p - 1 ) - 1;
	@exchanges2 = map {
	    my $i = $_;
	    map {
		[
		    [ $s1pair[$_][0], $s2pair[ $i - $_ ][0] ],
		    [ $s1pair[$_][1], $s2pair[ $i - $_ ][1] ]
		]
	      } ( max 0, $i - ( $p - 1 ) * ( $p - 2 ) / 2 + 1 )
	      .. ( min( ( $p - 1 ) * ( $p - 2 ) / 2 - 1, $i ) )
	} 0 .. ( $p - 1 ) * ( $p - 2 ) - 2;
    }
    elsif ($oddBracket)
    {
	my $pPlus = $p+1;
	my @s1pair = map {
	    my $i = $_;
	    map { [ $i - $_-1, $i-1 ] } 1 .. $i-1
	} reverse 3 .. $pPlus - 1;
	my @s2pair = map {
	    my $i = $_;
	    map { [ $i-1, $i+$_-1 ] } 1 .. 2 * ( $pPlus - 1 ) - $i
	} $pPlus .. 2 * ( $pPlus - 1 ) - 1;
	@exchanges2 = map {
	    my $i = $_;
	    map {
		[
		    [ $s1pair[$_][0], $s2pair[ $i - $_ ][0] ],
		    [ $s1pair[$_][1], $s2pair[ $i - $_ ][1] ]
		]
	      } ( max 0, $i - ( $pPlus - 1 ) * ( $pPlus - 2 ) / 2 + 1 )
	      .. ( min( ( $pPlus - 1 ) * ( $pPlus - 2 ) / 2 - 2, $i ) )
	} 0 .. ( $pPlus - 1 ) * ( $pPlus - 2 ) - 3;
    }
    push @exchanges, @exchanges2;
    return sub {
	my $exchange = shift @exchanges;
        return ("last S1,S2 exchange") unless $exchange;
    	$self->resetS12;
    	my $s1 = $self->s1;
    	my $s2 = $self->s2;
    	my @members = (@$s1, @$s2);
    	# my @members = @{ $self->members };
        ( $members[ $_->[0] ], $members[ $_->[1] ] ) =
          ( $members[ $_->[1] ], $members[ $_->[0] ] )
          for @$exchange;
	my $number = $letter++;
	die "undef player in exchange $number of S1, S2" if
		any { not defined } @members;
        return "exchange $number", @members;
      }
}


=head2 score

	$group->score

Gets/sets the score of the score group.

=cut

sub score {
    my $self  = shift;
    my $score = shift;
    if ( defined $score ) { $self->{score} = $score; }
    elsif ( exists $self->{score} ) { return $self->{score}; }
    return;
}


=head2 number

	$group->number

Gets/sets the bracket's number, a number from 1 to the number of separate brackets, remainder groups and bye groups in the tournament. Don't use this number for anything important.

=cut

sub number {
    my $self  = shift;
    my $number = shift;
    if ( defined $number ) { $self->{number} = $number; }
    elsif ( exists $self->{number} ) { return $self->{number}; }
    return;
}


=head2 badpair

	$group->badpair

Gets/sets the badpair, the position, counting from zero, of the first pair in S1 and S2 for which pairing failed in a previous attempt in C6. This is the first position at which the next ordering of S2 will differ from the previous one. All orderings between these two orderings will not result in a criteria-compliant pairing.

=cut

sub badpair {
    my $self    = shift;
    my $badpair = shift;
    if ( defined $badpair ) { $self->{badpair} = $badpair; }
    elsif ( defined $self->{badpair} ) { return $self->{badpair}; }
    return;
}


=head2 members

	$group->members

Gets/sets the members of the score group as an anonymous array of player objects. The order of this array is important. The first half is paired with the second half.

=cut

sub members {
    my $self    = shift;
    my $members = shift;
    if ( defined $members ) { $self->{members} = $members; }
    elsif ( $self->{members} ) { return $self->{members}; }
    return;
}


=head2 c8swapper

	$pairing->c8swapper

Gets/sets an iterator through the different exchanges of players in the two halves of the bracket.

=cut

sub c8swapper {
    my $self      = shift;
    my $c8swapper = shift;
    if ( defined $c8swapper ) { $self->{c8swapper} = $c8swapper; }
    elsif ( $self->{c8swapper} ) { return $self->{c8swapper}; }
}


=head2 _floatCheck

        %b65TestResults = _floatCheck( \@testee, $checkLevels );

Takes a list representing the pairing of a bracket (see the description for _getNonPaired), and the various up- and down-float check levels. Returns an anonymous hash with keys: (a) 'badpos', the first element of the list responsible for violation of B6 or 5, if there was a violation of any of the levels, (b) 'passer', an anonymous array of the same form as \@testee, if there was no violation of any of the levels, and (c) 'message', a string noting the reason why the pairing is in violation of B6 or 5, and the id of the player involved. If there are multiple violations, the most important one is/should be returned. 

=cut

sub _floatCheck {
    my $self = shift;
    my $untested = shift;
    my @paired = @$untested;
    my @nopairs = $self->_getNonPaired(@paired);
    my $levels = shift;
    die "Float checks are $levels?" unless $levels and ref($levels) eq 'ARRAY';
    my $pprime = $self->pprime;
    my $s1 = $self->s1;
    my ($badpos, %badpos);
    my @pairtestee = @paired;
    my @nopairtestee = @nopairs;
    my @pairlevelpasser;
    my @nopairlevelpasser;
    my $message;
    B56: for my $level (@$levels)
    {
	my ($round, $direction, $checkedOne, $id);
	if ( $level =~ m/^B5/i ) { $round = 1; }
	else { $round = 2; }
	if( $level =~ m/Down$/i) { $direction = 'Down'; $checkedOne = 0 }
	elsif ( $level =~ m/Up$/i ) { $direction = 'Up'; $checkedOne = 1 }
	else { @pairlevelpasser = @pairtestee; last B56 }
	for my $pos ( 0 .. $#$s1 ) {
	    next unless defined $pairtestee[$pos];
	    my @pair = ( $pairtestee[$pos]->[0], $pairtestee[$pos]->[1] );
	    my @score = map { defined $_->score? $_->score: 0 } @pair;
	    my @float = map { $_->floats( -$round ) } @pair;
	    my $test = 0;
	    $test = ( $score[0] == $score[1] or $float[$checkedOne] ne
		$direction ) unless $direction eq 'None';# XXX check both?  
	    if ( $test ) { $pairlevelpasser[$pos] = \@pair; }
	    else {
		$badpos{$level} = defined $badpos{$level}? $badpos{$level}: $pos;
		$badpos = defined $badpos? $badpos: $pos;
		$id ||= $pair[$checkedOne]->pairingNumber;
	    }
	}
	if ($direction ne 'Up' and @nopairtestee and ( not $self->hetero or
					(grep {defined} @nopairtestee) == 1 ))
	{
	    #my $potentialDownFloaters =
	    #    	grep { grep { defined } @$_ } @nopairtestee;
	    for my $pos ( 0 .. $#nopairtestee ) {
		next unless defined $nopairtestee[$pos];
		my @pair = @{ $nopairtestee[$pos] } if defined
		    $nopairtestee[$pos] and ref $nopairtestee[$pos] eq 'ARRAY';
		my $tableTest = 0;
		my $idCheck;
		for my $player ( @pair) {
		    my $test = ( not defined $player or
			    ($player->floats(-$round) ne "Down") );
		    $idCheck ||= $player->pairingNumber if $player and
							    not $test;
		    $tableTest++ if $test;
		}
		if ( $tableTest >= 2 ) { $nopairlevelpasser[$pos] = \@pair; }
		else {
		    $badpos{$level} = defined $badpos{$level}? $badpos{$level}: $pos;
		    $badpos = defined $badpos? $badpos: $pos;
		    $id = $idCheck if $idCheck;
		}
	    }
	}
	my @retainables = grep { defined } @pairlevelpasser ;#
			# , grep { defined } @nopairlevelpasser;
	# my @nonfloaters = grep { grep { defined } @$_ } @retainables;
	if ( @retainables < $pprime or keys %badpos )
	# if ( @retainables < $pprime or $badpos )
	{
	    my $badpos;
	    for my $nextLevel ( @$levels )
	    {	   
		next unless defined $badpos{ $nextLevel };
		$badpos = $badpos{ $nextLevel };
		last;
	    }
	    my $pluspos = $badpos+1;
	    $message =
"$level, table $pluspos: $id NOK. Floated $direction $round rounds ago";
	    return badpos => $badpos, passer => undef, message => $message;
	}
    }
    continue {
	@pairtestee = @pairlevelpasser;
	@nopairtestee = @nopairlevelpasser;
	undef @pairlevelpasser;
	undef @nopairlevelpasser;
    }
    return badpos => undef, passer => \@pairlevelpasser, message => "B56: OK.";
}


=head2 _getNonPaired

	$bracket->_getNonPaired([$alekhine,$uwe],undef,[$deepblue,$yournewnike])

Takes a list representing the pairing of S1 and S2. Each element of the list is either a 2-element anonymous array ref (an accepted pair of players), or undef (a rejected pair.) Returns an array of the same form, but with the accepted player items replaced by undef and the undef items replaced by the pairs rejected. If there are more players in S2 than S1, those players are represented as [undef,$player].

=cut

sub _getNonPaired {
    my $self = shift;
    my @pairables = @_;
    my $s1 = $self->s1;
    my $s2 = $self->s2;
    my @nopairs;
    for my $pos ( 0..$#pairables )
    {
	$nopairs[$pos] = [ $s1->[$pos], $s2->[$pos] ] unless
					defined $pairables[$pos];
    }
    for my $pos ( $#pairables+1 .. $#$s1 )
    {
	$nopairs[$pos] = [ $s1->[$pos], $s2->[$pos] ];
    }
    for my $pos ( $#$s1+1 .. $#$s2 )
    {
	$nopairs[$pos] = [ undef, $s2->[$pos] ];
    }
    return @nopairs;
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

    perldoc Games::Tournament::Swiss::Bracket

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Swiss-Bracket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Swiss-Bracket>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Swiss-Bracket>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Swiss-Bracket>

=back

=head1 ACKNOWLEDGEMENTS

See L<http://www.fide.com/official/handbook.asp?level=C04> for the FIDE's Swiss rules.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Swiss::Bracket

# vim: set ts=8 sts=4 sw=4 noet:
