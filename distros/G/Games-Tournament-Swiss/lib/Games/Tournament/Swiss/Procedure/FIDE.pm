package Games::Tournament::Swiss::Procedure::FIDE;
$Games::Tournament::Swiss::Procedure::FIDE::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:53
# $Id: /swiss/trunk/lib/Games/Tournament/Swiss/Procedure/FIDE.pm 1657 2007-11-28T09:30:59.935029Z dv  $

use warnings;
use strict;
use Carp;

use List::Util qw/first/;
use List::MoreUtils qw/any all notall/;

use constant ROLES      => @Games::Tournament::Swiss::Config::roles;
use constant FIRSTROUND => $Games::Tournament::Swiss::Config::firstround;

use base qw/Games::Tournament::Swiss/;
use Games::Tournament::Contestant::Swiss;

use constant    C1        => 'C1';
use constant    C2        => 'C2';
use constant    C3        => 'C3';
use constant    C4        => 'C4';
use constant    C5        => 'C5';
use constant    C6PAIRS   => 'C6PAIRS';
use constant    C6OTHERS  => 'C6OTHERS';
use constant    C7        => 'C7';
use constant    C8        => 'C8';
use constant    C9        => 'C9';
use constant    C10       => 'C10';
use constant    C11       => 'C11';
use constant    C12       => 'C12';
use constant    C13       => 'C13';
use constant    BYE       => 'bye';
use constant    C14       => 'C14';
use constant    FLOAT     => "FLOAT";
use constant    START     => "START";
use constant    LAST      => "LAST";
use constant    ERROR     => "ERROR";
use constant    MATCH     => "MATCH";
use constant    NEXT      => "NEXT";
use constant    PREV      => "PREV";

=head1 NAME

Games::Tournament::Swiss::Procedure::FIDE - FIDE Swiss Rules Based on Rating 04.1

=cut

=head1 SYNOPSIS

 $tourney = Games::Tournament::Swiss->new( rounds => 2, entrants => [ $a, $b, $c ] );
 %groups = $tourney->formBrackets;
 $pairing = $tourney->pairing( \%groups );
 @pairs = $pairing->matchPlayers;


    ...

=head1 DESCRIPTION

FIDE Swiss Rules C 04.1 Based on Rating describes an algorithm to pair players. The algorithm starts with the highest bracket, and then pairs each bracket in turn. ending with the lowest bracket, floating players up and down to find acceptable matches, but also undoing pairings in higher score groups, if this will help the pairing of lower score groups. This module pairs players on the basis of that algorithm.

=head1 METHODS

=head2 new

 $pairing = Games::Tournament::Swiss::Procedure->new( \@groups );

Creates a FIDE C 04.1 algorithm object on a reference to a list of scoregroups ordered by score, the group with highest score first, the one with lowest score last. This object has a matches accessor to the games (cards) the algorithm has made, an incompatibles accessor to previous matches ofthe players, a stack of groups previous to this one at this point in the pairing to which we can go back and XXX. This constructor is called in the Games::Tournament::Swiss::pairing method.

=cut 

sub new {
    my $self     = shift;
    my %args     = @_;
    return bless {
        round        => $args{round},
        brackets     => $args{brackets},
        whoPlayedWho => $args{whoPlayedWho},
        colorClashes => $args{colorClashes},
        badpair      => undef,
        byes         => $args{byes},
        matches      => {},
	previousBracket => [],
	logged => {}
      },
      "Games::Tournament::Swiss::Procedure";
}

=head2 matchPlayers

 @pairs = $pairing->matchPlayers;

Run the FIDE C 04.1 algorithm adding matches to $pairing->matches. NOTE: At one point in deveopment of this module, I was passing round the args, rather than storing them in the object, because of problems with storing. What were those problems? What does matchPlayers return? Is it a hash or the matches or what?
=cut 

sub matchPlayers {
    my $self    = shift;
    my %machine = (
        START, [ \&start, NEXT ],
        C1, [ \&c1, C2, NEXT, C13, C12, C1 ],
        C2,      [ \&c2,      C3 ],
        C3,      [ \&c3,      C4 ],
        C4,      [ \&c4,      C5 ],
        C5,      [ \&c5,      C6PAIRS ],
        C6PAIRS, [ \&c6pairs, C6OTHERS, C7, NEXT ],
        C6OTHERS, [ \&c6others, NEXT, C1, C2, C10, C13 ],
        C7, [ \&c7, C6PAIRS, C8, C9, C10, C11 ],
        C8,  [ \&c8,  C5, C9,  C10 ],
        C9,  [ \&c9,  C4, C10 ],
        C10, [ \&c10, C7, C4,  C11 ],
        C11, [ \&c11, C12, C4, C7 ],
        C12,    [ \&c12,    C13, C7, ],
        C13,    [ \&c13,    C14, C7, C1, BYE ],
        C14,    [ \&c14,    NEXT, C4, C13 ],
	BYE,	[ \&bye,    LAST, C13 ],
        NEXT,   [ \&next,   C1, LAST ],
        PREV,   [ \&prev,   C1, LAST ],
        LAST,  [ undef, LAST ],
        ERROR, [ undef, ERROR ],
    );
    my $state    = START;
    my $oldState = $state;
    my %args     = %$self;
    for ( ; ; ) {
        my $transitions = $machine{$state};
	die "$oldState, $state, $transitions" unless $transitions and ref($transitions) eq 'ARRAY';
        my ( $action, @alterStates ) = @$transitions;
        $oldState = $state;
        ( $state, %args ) = $action->( $self, %args ) if $action;
	if ( any { $_ eq $oldState } $self->loggedProcedures )
	{
	    my %log = $self->tailLog($oldState);
	    $self->logreport( $oldState . "," . $log{$oldState} ) if %log;
	}
        if ( $state eq ERROR ) {
            die
qq/Pairing error: $args{msg}. Pairing NOT complete\n/;
        }
        if ( $state eq LAST ) {
	    $self->message( $args{msg} );
	    return $self; }
        die "No transition defined from $oldState to $state"
          unless grep m/$state/, @alterStates;
    }
}


=head2 message

 $pairing->message;

Something about the success or failure of the pairing procedure as far as it concerns the user. This is not a message about the success or failure of the Games::Tournament::Swiss::Procedure::FIDE code as in 'warn', or a logging of the progress of the players in their brackets through the FIDE pairing procedure as in 'log', or a message about a problem coding the FIDE algorithm, as in 'ERROR'.

=cut 

sub message {
    my $self = shift;
    my $message = shift;
    if ( defined $message ) { $self->{message} .= $message; }
    elsif ( $self->{message} ) { return $self->{message}; }
}


=head2 logreport

 $pairing->logreport('C6: Pairing S1 and S2');

Accumulates a log in string form, of the progress of the players in their brackets through the FIDE pairing procedure, using the logging methods of Games::Tournament, and returning the log accumulated if no arguments are passed.

=cut 

sub logreport {
    my $self = shift;
    my $logreport = shift;
    if ( defined $logreport ) { $self->{logreport} .= $logreport; }
    elsif ( $self->{logreport} ) { return $self->{logreport}; }
}


=head2 start

 $pairing->start;

Start at the start before the first bracket. Go to the next bracket.

=cut 

sub start {
    my $self  = shift;
    my $index = $self->thisBracket;
    my $groups = $self->brackets;
    die "Can't start. Already started." if defined $index;
    $self->thisBracket('START');
    my $round    = $self->round;
    my $brackets = $self->brackets;
    my $banner   = "Round $round:  ";
    for my $bracket ( reverse sort keys %$brackets ) {
        my $members = $brackets->{$bracket}->members;
        my $score   = $brackets->{$bracket}->score;
        $banner .= "@{[map { $_->pairingNumber } @$members]} ($score), ";
    }
    $self->log( $banner );
    return NEXT;
}


=head2 next

 $pairing->next;

Pair the next bracket. End if this is the last bracket. Die if we are not pairing any bracket now.

=cut 

sub next {
    my $self  = shift;
    my $index = $self->thisBracket;
    die "No bracket being paired" unless defined $index;
    return LAST if defined $index and $index eq $self->lastBracket;
    my $next    = $self->nextBracket;
    die "No next bracket to $index-Bracket" unless defined $next;
    my $groups = $self->brackets;
    my $nextBracket = $groups->{$next};
    die "Next bracket is: $next Bracket?" unless defined $nextBracket
		    and $nextBracket->isa('Games::Tournament::Swiss::Bracket');
    my $members = $nextBracket->members;
    my @ids = map {$_->pairingNumber} @$members;
    my $number = $nextBracket->number;
    $self->thisBracket($next);
    $self->log( "$next-Bracket [$number]: @ids" );
    return C1;
}


=head2 prev

 $pairing->prev;

Pair the previous bracket. End if this is the first bracket.

=cut 

sub prev {
    my $self  = shift;
    my $brackets = $self->brackets;
    my $index = $self->thisBracket;
    my $bracket = $brackets->{$index};
    return LAST if defined $index and $index eq $self->firstBracket;
    my $prevIndex = $self->previousBracket;
    my $prevBracket = $brackets->{$prevIndex};
    my $members = $prevBracket->members;
    my $number = $prevBracket->number;
    $self->thisBracket($prevIndex);
    my @ids = map {$_->pairingNumber} @$members;
    $self->log( "Previous, Bracket $number ($prevIndex): @ids");
    return C1;
}


=head2 c1

 $pairing->c1;

If the score group contains a player for whom no opponent can be found (B1,B2), and if this player is a downfloater, go to C12 to find another player to downfloat instead. Or if this is the last group, go to C13. Otherwise, downfloat the unpairable player.

=cut 

sub c1 {
    my $self          = shift;
    my $groups        = $self->brackets;
    my $alreadyPlayed = $self->whoPlayedWho;
    my $colorClashes  = $self->colorClashes;
    my $index = $self->thisBracket;
    my $group         = $groups->{$index};
    my $number         = $group->number;
    my $members       = $group->residents;
    my @unpairables;
    my $nokmessage = 'NOK.';
    if ( @$members == 1 ) {
	my $member = $members->[0];
        push @unpairables, $member;
	my $id = $member->pairingNumber;
	$nokmessage .= " $id";
	$self->log( $nokmessage . " only member in $index-Bracket [$number]" );
    }
    else {
        for my $player (@$members) {
            my $id         = $player->id;
	    my $pairingNumber = $player->pairingNumber;
            my $rejections = 0;
            my @candidates = grep { $_ != $player } @$members;
            my @ids        = map { $_->id } @candidates;
            foreach my $candidate (@ids) {
                if    ( $alreadyPlayed->{$id}->{$candidate} ) { $rejections++; }
                elsif ( $colorClashes->{$id}->{$candidate} )  { $rejections++; }
            }
            if ( $rejections >= @candidates or @candidates == 0 ) {
                $nokmessage .= " $pairingNumber";
                push @unpairables, $player;
            }
        }
        if (@unpairables) {
            my @ids = map { $_->pairingNumber } @unpairables;
            $self->log(
                "$nokmessage: @ids B1a/B2a incompatible in $number ($index)");
        }
    }
    my @unpairableIds = map {$_->pairingNumber} @unpairables;
    my ($previousIndex, $previousBracket, $previousMembers, $previousNumber);
    $previousIndex = $self->previousBracket;
    $previousBracket = $groups->{$previousIndex} if $previousIndex;
    $previousMembers = $previousBracket->members if $previousBracket;
    $previousNumber = $previousBracket->number if $previousBracket;
    if (@unpairables) {
        if ( $index eq $self->lastBracket and $index ne $self->firstBracket )
	{
	    $self->log( "@unpairableIds in last bracket, $number ($index)." );
            return C13;
        }
        elsif ((grep {$_->floating and $_->floating eq 'Down'} @unpairables)
		    and $previousIndex and $previousMembers )
	{
	    $self->log(
	      "@unpairableIds floaters from $previousNumber ($previousIndex)" );
	    return C12;
        }
        elsif (defined $self->nextBracket)
	{
	    my $next = $self->nextBracket;
	    my $nextBracket = $groups->{$next};
	    my $nextNumber = $nextBracket->number;
	    $self->log(
		"Floating @unpairableIds down to $next-Bracket [$nextNumber]" );
	    $group->exit($_) for @unpairables;
	    $_->floating('Down') for @unpairables;
	    $nextBracket->entry($_) for @unpairables;
	    my @originals = map {$_->pairingNumber} @{$group->members};
	    my @new = map {$_->pairingNumber} @{$nextBracket->members};
            $self->log( "[$number] @originals & [$nextNumber] @new" );
            if ( @unpairables == @$members ) {
		my $previous = $self->previousBracket;
		$self->log( "$index-Bracket [$number] dissolved" );
		$self->thisBracket($previous);
		$group->dissolved(1);
		return NEXT;
	    }
	    else { return C2; }
        }
	else {
	    $self->log(
	    "No destination for unpairable @unpairableIds. Go to C2" );
	    return C2;
	}
    }
    else {   
	$self->log( "B1,2 test: OK, no unpairables" );
	return C2;
    }
    return ERROR, msg => "Fell through C1 in $number ($index)";
}


=head2 rejectionTest

 ($message, @unpairables) = $pairing->rejectionTest(@members)

Returns the unpairable players in a score bracket, if it contains players for whom no opponent can be found (B1,B2). This is useful in C1, but it is also useful in pairing a remainder group, where we want to know the same thing but don't want to take the same action as in C1. It would be convenient to know that the group is unpairable as-is, without going through all the C6,7,8,9,10 computations.

=cut 

sub rejectionTest {
    my $self          = shift;
    my @members        = @_;
    my $alreadyPlayed = $self->whoPlayedWho;
    my $colorClashes  = $self->colorClashes;
    my @unpairables;
    my $nokmessage = 'NOK.';
    if ( @members == 1 ) {
	my $member = $members[0];
        push @unpairables, $member;
	my $id = $member->pairingNumber;
	$nokmessage .= " $id only member";
    }
    else {
	  for my $player (@members) {
	  my $id = $player->id;
            my $rejections  = 0;
            my @candidates = grep { $_ != $player } @members;
            my @ids       = map { $_->id } @candidates;;
            foreach my $candidate ( @ids ) {
		if ( $alreadyPlayed->{$id}->{$candidate} ) { $rejections++; }
		elsif ( $colorClashes->{$id}->{$candidate} ) { $rejections++; }
            }
            if ( $rejections >= @candidates or @candidates == 0 ) {
                push @unpairables, $player;
            }
        }
	if ( @unpairables )
	{
	    my @ids = map { $_->pairingNumber } @unpairables;
	    $nokmessage .= " @ids B1a/B2a incompatible";
	}
    }
    if ( @unpairables ) { return $nokmessage, @unpairables; }
    else {  return "B1,2 test: OK, no unpairables"; }
}


=head2 c2

 $pairing->c2

Determine x according to A8. But only if xprime has not been defined for the bracket (remainder group) by C11. See B4 and http://chesschat.org/showthread.php?p=173273#post173273

=cut 

sub c2 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $this = $self->thisBracket;
    my $group  = $groups->{$this};
    my $number  = $group->number;
    my $x      = $group->x;
    $group->xprime( $group->x ) unless defined $group->xprime;
    my $xprime = $group->xprime;
    $self->log( "x=$xprime" );
    return C3;
}


=head2 c3

 $pairing->c3

Determine p according to A6.

=cut 

sub c3 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $this = $self->thisBracket;
    my $group  = $groups->{$this};
    my $number  = $group->number;
    my $p      = $group->p;
    $group->pprime( $group->p );
    if ( $group->hetero ) { $self->log( "p=$p. Heterogeneous."); }
    else { $self->log( "p=$p. Homogeneous."); }
    return C4;
}


=head2 c4

 $pairing->c4

The highest players in S1, the others in S2.

=cut 

sub c4 {
    my $self    = shift;
    my $groups  = $self->brackets;
    my $group   = $groups->{$self->thisBracket};
    my $members = $group->members;
    my $index   = $self->thisBracket;
    my $number   = $group->number;
    $group->resetS12;
    my $s1      = $group->s1;
    my $s2      = $group->s2;
    my @s1ids = map {$_->pairingNumber} @$s1;
    my @s2ids = map {$_->pairingNumber} @$s2;
    $self->log( "S1: @s1ids & S2: @s2ids" );
    die "Empty S1 in $index-Bracket ($number) with S2: @s2ids." unless @$s1;
    die "Empty $index-Bracket ($number) with  S1: @s1ids." unless @$s2;
    return C5;
}


=head2 c5

 $pairing->c5

Order the players in S1 and S2 according to A2.

=cut 

sub c5 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $group   = $groups->{ $self->thisBracket };
    my $number  = $group->number;
    my $members = $group->members;
    my $x       = $group->xprime;
    my $s1      = $group->s1;
    my $s2      = $group->s2;
    my @s1      = $self->rank(@$s1);
    my @s2      = $self->rank(@$s2);
    my @s1ids = map {$_->pairingNumber} @s1;
    my @s2ids = map {$_->pairingNumber} @s2;
    $self->log( "ordered: @s1ids\n\t       & @s2ids" );
    $group->s1( \@s1 );
    $group->s2( \@s2 );
    for my $member ( @{ $group->s2 } ) {
        die "$member->{id} was in ${number}th bracket more than once"
          if ( grep { $_->id eq $member->id } @{ $group->s2 } ) > 1;
    }
    $groups->{ $self->thisBracket } = $group;
    $self->brackets($groups);
    return C6PAIRS;
}


=head2 c6pairs

 Games::Tournament::Swiss::Procedure->c6pairs($group, $matches)

Pair the pprime players in the top half of the scoregroup in order with their counterparts in the bottom half, and return an array of tentative Games::Tournament::Card matches if B1, B2 and the relaxable B4-6 tests pass. In addition, as part of the B6,5 tests, check none of the UNpaired players in a homogeneous bracket were downfloated in the round before (B5) or the round before that (B6), or that there is not only one UNpaired, previously-downfloated player in a heterogeneous group, special-cased following Bill Gletsos' advice at http://chesschat.org/showpost.php?p=142260&postcount=158. If more than pprime tables are paired, we take the first pprime tables.

=cut 

sub c6pairs {
    my $self   = shift;
    my $groups = $self->brackets;
    my $index = $self->thisBracket;
    my $group  = $groups->{ $index };
    my $number  = $group->number;
    my $pprime      = $group->pprime;
    my $s1     = $group->s1;
    my $s2     = $group->s2;
    return NEXT unless @$s1 and @$s2;
    die "More players in S1 than in S2 in $number($index)." if $#$s1 > $#$s2;
    die "zero players in S1 or S2 in $number($index)" unless @$s1 and @$s2;
    my $whoPlayedWho = $self->whoPlayedWho;
    my $colorClashes = $self->colorClashes;
    $group->badpair(undef);
    my @testee;
    for my $pos ( 0..$#$s1, $#$s1+1..$#$s2 )
    {
	$testee[$pos] = [ $s1->[$pos], $s2->[$pos] ] if $pos <= $#$s1;
	$testee[$pos] = [ undef, $s2->[$pos] ] if $pos > $#$s1;
    }
    my ($badpos, @B1passer, @B2passer, @Xpasser, @B56passer, $passer);
    B1: for my $pos (0..$#$s1)
    {
	my @pair = @{$testee[$pos]};
	my $test = not defined $whoPlayedWho->{$pair[0]->id}->{$pair[1]->id};
	if ( $test ) { $B1passer[$pos] = \@pair; }
	else { $badpos = defined $badpos? $badpos: $pos; }
    }
    unless ( (grep { defined $_ } @B1passer) >= $pprime )
    {
	my $pluspos = $badpos+1;
	$self->log( "B1a: table $pluspos NOK" );
	$group->badpair($badpos);
	return C7;
    }
    $badpos = undef;
    die "no pairs after B1 test in $number($index)" unless @B1passer;
    B2: for my $pos (0..$#$s1)
    {
	next unless defined $B1passer[$pos];
	my @pair = ( $B1passer[$pos]->[0], $B1passer[$pos]->[1] );
	my $test = not defined $colorClashes->{$pair[0]->id}->{$pair[1]->id};
	if ( $test ) { $B2passer[$pos] = \@pair; }
	else { $badpos = defined $badpos? $badpos: $pos; }
    }
    unless ( (grep { defined $_ } @B2passer) >= $pprime )
    {
	my $pluspos = $badpos+1;
	$self->log( "B2a: table $pluspos NOK" );
	$group->badpair($badpos);
	return C7;
    }
    die "no pairs after B2 test in $number($index)" unless @B2passer;
    my $x = $group->xprime;
    my $quota = 0;
    $badpos = undef;
    B4: for my $pos ( 0 .. $#$s1 ) {
	next unless defined $B2passer[$pos];
	my @pair = ( $B2passer[$pos]->[0], $B2passer[$pos]->[1] );
	$quota += ( defined $pair[0]->preference->role
              and defined $pair[1]->preference->role
              and $pair[0]->preference->role eq
              $pair[1]->preference->role );
	if ( $quota <= $x ) {
	    $group->{xdeduction} = $quota if $group->hetero;
	    $Xpasser[$pos] = \@pair;
	}
	else { $badpos = defined $badpos? $badpos: $pos; last B4; }
    }
    unless ( (grep { defined $_ } @Xpasser) >= $pprime )
    {
	my $pluspos = $badpos+1;
	$self->log( "B4: x=$x, table $pluspos NOK" );
	$group->badpair($badpos);
	return C7;
    }
    die "no pairs after B4 test in $number($index)" unless @Xpasser;
    $badpos = undef;
    # my @nonpaired = $group->_getNonPaired(@Xpasser);
    my $checkLevels = $self->floatCriteriaInForce( $group->floatCheckWaive );
    my %b65TestResults = $group->_floatCheck( \@Xpasser, $checkLevels );
    $badpos = $b65TestResults{badpos};
    $self->log( $b65TestResults{message} );
    if ( defined $badpos )
    {
	my $pluspos = $badpos+1;
	$group->badpair($badpos);
	return C7;
    }
    $passer = $b65TestResults{passer};
    die "no pairs after B65 test in $number($index)" unless @$passer;
    for my $pos ( 0 .. $#$passer ) {
	next unless defined $passer->[$pos];
	my @pair = @{$passer->[$pos]};
	my @score = map { defined $_->score? $_->score: 0 } @pair;
	if ( $score[0] > $score[1] )
	{
	    $pair[0]->floating('Down');
	    $pair[1]->floating('Up');
	}
	elsif ( $score[0] == $score[1] )
	{
	    map { $_->floating('Not') } @pair;
	}
	else {
	    $pair[0]->floating('Up');
	    $pair[1]->floating('Down');
	}
    }
    my @nonpaired = $group->_getNonPaired(@$passer);
    my @paired = grep { defined } @$passer;
    if ( $#paired >= $pprime )
    {
	my @unrequired = @paired[ $pprime .. $#paired ];
	splice @paired, $pprime;
	unshift @nonpaired, @unrequired;
    }
    @nonpaired = map { my $pair=$_; grep { defined } @$pair } @nonpaired;
    my @tables = grep { defined $passer->[$_-1] } 1..@$passer;
    $self->log( "$index-Bracket ($number) tables @tables paired. OK" );
    $self->nonpaired(\@nonpaired) if @nonpaired;
    my $allMatches = $self->matches;
    my ($pairmessage, @matches) = $self->colors( paired => \@paired ) if @paired;
    $self->log( $pairmessage );
    if ( $group->hetero and @nonpaired and $group->bigGroupXprime )
    {
	my $bigXprime = $group->bigGroupXprime;
	my $usedX = $group->{xdeduction};
	my $remainingX = $bigXprime - $usedX;
	$self->log(
"$usedX of $bigXprime X points used. $remainingX left for remainder group" );
    }
    $allMatches->{$index} = \@matches;
    if (@paired) {if ( @nonpaired ) { return C6OTHERS } else { return NEXT } }
    return ERROR, msg => "No paired in C6PAIRS";
}


=head2 c6others

 Games::Tournament::Swiss::Procedure->c6others($group, $matches)

After pairing players, if there are remaining players in a homogeneous group, float them down to the next score group and continue with C1 (NEXT). In a heterogeneous group, start at C2 with the remaining players, now a homogeneous remainder group.

=cut 

sub c6others {
    my $self   = shift;
    my $groups = $self->brackets;
    my $index =  $self->thisBracket;
    my $group     = $groups->{$index};
    my $number = $group->number;
    my $nonpaired = $self->nonpaired;
    die "Unpaired players are: $nonpaired?" unless defined $nonpaired and
							    @$nonpaired;
    my $islastBracket = ( $index eq $self->lastBracket );
    unless ( $group->hetero and @$nonpaired > 1 or $islastBracket ) {
	my $next = $self->nextBracket;
	my $nextBracket = $groups->{$next};
	my $nextNumber = $nextBracket->number;
	my @nextMembers = map {$_->pairingNumber} @{$nextBracket->members};
        for my $evacuee (@$nonpaired) {
            $group->exit($evacuee);
            $evacuee->floating('Down');
            $nextBracket->entry($evacuee);
        }
	my @floaters = map {$_->pairingNumber} @$nonpaired;
	my @pairIds = map {$_->pairingNumber} @{$group->members};
        $self->log(
"Floating remaining @floaters Down. [$number] @pairIds. @floaters => [$nextNumber] @nextMembers" );
        return NEXT;
    }
    else {
	my $xprime = $group->bigGroupXprime;
	my $remainingX =  $group->{xdeduction}? $xprime - $group->{xdeduction}:
	    $xprime;
        my $remainderGroup = Games::Tournament::Swiss::Bracket->new(
            score       => $group->score,
            remainderof => $group,
	    number      => "${number}'s Remainder Group",
	    xprime => $remainingX,
        );
	# $group->{remainder} ||= $remainderGroup;
	$group->{remainder} = $remainderGroup;
	my $remaIndex = "${index}Remainder";
	if ( $islastBracket and @$nonpaired == 1 ) { 
	    $remaIndex = "${index}Bye";
	    $remainderGroup->{number} = "${number}'s Bye";
	}
        $groups->{$remaIndex} = $remainderGroup;
	my $remainderIndex = $self->nextBracket;
	my $remainder = $groups->{$remainderIndex};
	my $remainderNumber = $remainder->number;
        for my $remainer (@$nonpaired) {
            $group->exit($remainer);
	    # $remainder->entry($remainer);
	    $remainderGroup->entry($remainer);
        }
	my @remains = map {$_->pairingNumber} @$nonpaired;
	my $members = $group->members;
	my @memberIds = map {$_->pairingNumber} @$members;
	my @next = map {$_->pairingNumber} @{$remainderGroup->members};
        $self->log( "Remaindering @remains.
    [$number] @memberIds & [$remainderNumber] @next" );
	$remainderGroup->{c10repaired} = 1 if $group->{c10repaired};
	$remainderGroup->{lowfloaterlastshuffle} = 1
	    if $group->{lowfloaterlastshuffle}; 
	$remainderGroup->{c11repaired} = 1 if $group->{c11repaired};
	$remainderGroup->{lastheteroshuffle} = 1
	    if $group->{lastheteroshuffle};
	$self->brackets($groups);
	if ( $islastBracket ) {
	    return NEXT;
	}
	$self->thisBracket($remainderIndex);
	my ( $rejectionSlip, @rejections) = $self->rejectionTest(@$nonpaired);
	if ( @rejections and not @$nonpaired % 2 )
	{
	    $self->log(
"$rejectionSlip. $remainderIndex-Group [$remainderNumber] unpairable. Go C10" );
	    $remainderGroup->{lastshuffle} = 1;
	    return C10;
	}
	else { return C2; }
    }
}


=head2 c7

	$next = $pairing->c7
	while ( my @s2 = &$next )
	{
	    create match cards unless this permutation is incompatible;
	}

Apply a new transposition of S2 according to D1 and restart at C6. But take precautions to prevent transposing players who are no longer in the bracket, when finding a different pairing, returning from C10,12,13. In particular, when returning from C10, stop when the last alternative pairing for the lowest downfloater has been tried.

=cut 

sub c7 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $index =  $self->thisBracket;
    my $group   = $groups->{$index};
    my $number  = $group->number;
    if ( $self->{lowfloaterlastshuffle} )
    {
	$self->log("last C10 transposition in $index-Bracket [$number]");
	return C10;
    }
    my $s1      = $group->s1;
    my $s2      = $group->s2;
    my $badpair = $group->badpair;
    $badpair = $#$s2 if not defined $badpair;
    my @newS2   = $group->c7shuffler($badpair);
    unless (@newS2) {
        $self->log("last transposition in $index-Bracket [$number]");
        $group->resetS12;
	$group->{lastshuffle} = 1;
	$group->{lastheteroshuffle} = 1 if ($group->hetero or
	($group->{remainderof} and $group->{remainderof}->{lastheteroshuffle}));
	# return C11 if $group->{c11repaired};
	# return C10 if $group->{c10repaired};
        return C8 unless $group->hetero;
        return C9;
    }
    $group->s2( \@newS2 );
    $group->members( [ @$s1, @newS2 ] );
    my @newOrder = map { $_->pairingNumber } @newS2;
    $self->log( "         @newOrder");
    my $lastC10shuffle = $group->{lastC10Alternate};
    if ( $lastC10shuffle and ref $lastC10shuffle eq 'ARRAY' and @$lastC10shuffle
	and all {$newOrder[$_] == $lastC10shuffle->[$_]} 0..$#$lastC10shuffle )
    {
	$group->{lowfloaterlastshuffle} = 1;
    }
    $groups->{ $self->thisBracket } = $group;
    return C6PAIRS;
}


=head2 c8

	$next = $pairing->c8
	while ( my ($s1, $s2) = &$next )
	{
	    create match cards unless this exchange is incompatible;
	}

In case of a homogeneous (remainder) group: apply a new exchange between S1 and S2 according to D2. Restart at C5.

=cut 

sub c8 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $this = $self->thisBracket;
    my $group = $groups->{$this};
    my $number  = $group->number;
    my $swapper;
    if ( $group->c8swapper ) {
        $swapper = $group->c8swapper;
    }
    else {
        $swapper = $group->c8iterator;
        $group->c8swapper($swapper);
    }
    my ($message, @newMembers) = &$swapper;
    $self->log( "$message in $this-Bracket [$number]" );
    unless (@newMembers) {
      $swapper = $group->c8iterator;
        $group->c8swapper($swapper);
        return C9;
    }
    my $p  = $group->p;
    my @s1 = @newMembers[ 0 .. $p - 1 ];
    my @s2 = @newMembers[ $p .. $#newMembers ];
    $group->s1( \@s1 );
    $group->s2( \@s2 );
    $self->log(
    "@{[map { $_->pairingNumber } @s1]}, @{[map { $_->pairingNumber } @s2]}" );
    $groups->{$this} = $group;
    $self->{brackets} = $groups;
    return C5;
}


=head2 c9

 Games::Tournament::Swiss::Procedure->c9

Drop, in order, criterion B6 (no identical float to 2 rounds before) and B5 (no identical float to previous round) for downfloats and restart at C4.

=cut 

sub c9 {
    my $self    = shift;
    my $groups  = $self->brackets;
    my $index = $self->thisBracket;
    my $group   = $groups->{ $index };
    my $number   = $group->number;
    if ( $group->floatCheckWaive eq 'None' ) {
        $group->floatCheckWaive('B6Down');
	delete $group->{lastshuffle};
	delete $group->{lastheteroshuffle};
        $self->log( "No pairing with float checks on. Dropping B6 for Downfloats in $index-Bracket [$number]" );
        return C4;
    }
    elsif ( $group->floatCheckWaive eq 'B6Down' ) {
        $group->floatCheckWaive('B5Down');
	delete $group->{lastshuffle};
	delete $group->{lastheteroshuffle};
        $self->log( "No pairing with B6 check off. Dropping B5 for Downfloats in $index-Bracket [$number]" );
        return C4;
    }
    elsif ( $group->floatCheckWaive eq 'B5Down' ) {
	$self->log(
"No pairing with all Downfloat checks dropped in $index-Bracket [$number]" );
	return C10;
    }
    elsif ( $group->floatCheckWaive eq 'B6Up' ) {
	$self->log(
"No pairing with all Downfloat checks dropped in $index-Bracket [$number]" );
	return C10;
    }
    elsif ( $group->floatCheckWaive eq 'B5Up' ) {
	$self->log(
"No pairing with all Downfloat checks dropped in $index-Bracket [$number]" );
	return C10;
    }
    elsif ( $group->floatCheckWaive eq 'All' ) {
        $group->floatCheckWaive('B6Down');
        $self->log( "No Pairing with all Downfloat checks dropped. Pairing again with B6 dropped in $index-Bracket [$number]" );
	return C4;
    }
    return ERROR, msg => "$index-Bracket [$number] fell through C9";
}


=head2 c10

 Games::Tournament::Swiss::Procedure->c10

In case of a homogeneous remainder group: undo the pairing of the lowest moved down player paired and try to find a different opponent for this player by restarting at C7. If no alternative pairing for this player exists then drop criterion B6 first and then B5 for upfloats and restart at C2 (C4 to avoid p, x resetting.) If we are in a C13 loop (check penultpPrime), avoid the C10 procedure. Why?

=cut 

sub c10 {
    my $self   = shift;
    my $brackets = $self->brackets;
    my $index = $self->thisBracket;
    my $group  = $brackets->{ $index };
    my $groupNumber = $group->number;
    my $lowFloat = $group->s1->[0]->pairingNumber;
    if ( $group->{c10repaired} and $group->{lowfloaterlastshuffle})
    {
	my ($heteroBracket, $heteroNumber, $heteroIndex);
	if ( $group->{remainderof} )
	{
	    $heteroBracket = $group->{remainderof};
	    $heteroNumber = $heteroBracket->number;
	    $heteroIndex = $self->index($heteroBracket);
	    my $repairgroupRemainder = $group;
	    my $lowest = $heteroBracket->s1->[0];
	    my $lowFloat = $lowest->pairingNumber;
	    my $inadequateS2member = $heteroBracket->s2->[0];
	    my $partnerId = $inadequateS2member->pairingNumber;
	    my $unpaired = $repairgroupRemainder->members;
	    $repairgroupRemainder->exit($_) for @$unpaired;
	    $_->floating('')            for @$unpaired;
	    $heteroBracket->entry($_)   for @$unpaired;
	    # $heteroBracket->floatCheckWaive('None');
	    # $heteroBracket->badpair(0);
	    $self->thisBracket($heteroIndex);
	    $repairgroupRemainder->dissolved(1);
	    delete $repairgroupRemainder->{lowfloaterlastshuffle};
	    delete $heteroBracket->{lowfloaterlastshuffle};
	    $self->log(
"Can't repair lowest downfloater, $lowFloat in $heteroIndex-Bracket [$heteroNumber]" );
	}
	elsif ( $group->hetero ) {
	    $heteroBracket = $group;
	    $heteroNumber = $groupNumber;
	    $heteroIndex = $index;
	    delete $heteroBracket->{lowfloaterlastshuffle};
	}
	if ( $heteroBracket->floatCheckWaive eq 'B5Up' ) {
	    $heteroBracket->floatCheckWaive('All');
	    $self->log(
"Float checks all dropped, but can't repair heterogeneous $index-Bracket [$groupNumber]. Go C11 " );
	    return C11;
	}
	elsif (  $heteroBracket->floatCheckWaive eq 'B6Down' or
			$heteroBracket->floatCheckWaive eq 'B5Down' ) {
	    $heteroBracket->floatCheckWaive('B6Up');
	    $self->log(
	"Dropping B6 for Upfloats in $heteroIndex-Bracket [$heteroNumber]");
	}
	elsif ( $heteroBracket->floatCheckWaive eq 'B6Up' ) {
	    $heteroBracket->floatCheckWaive('B5Up');
	    $self->log(
	"Dropping B5 for Upfloats in $heteroIndex-Bracket [$heteroNumber]");
	}
	$self->log(
	"Repairing whole of $heteroIndex-Bracket [$heteroNumber]" );
	return C4;
    }
    elsif ( $group->{remainderof} ) {
	if ( $group->{remainderof}->{c11repaired} or
			$group->{remainderof}->{c12repaired} )
	{
	    $self->log( "Passing $index-Bracket [$groupNumber] to C11." );
	    return C11;
	}
	my $remaindered = $group->members;
	my @remaindered = map {$_->pairingNumber} @$remaindered;
	my $heteroBracket = $group->{remainderof};
	my $index = $self->index($heteroBracket);
	my $number  = $heteroBracket->number;
	my @ids = map { $_->pairingNumber } @{ $heteroBracket->members };
	$self->log(
"Pairing of @ids in $index-Bracket [$number] failed pairing @remaindered in remainder group." );
	my $matches = delete $self->matches->{$index};
	    $group->dissolved(1);
	    # $heteroBracket->floatCheckWaive('None');
	    $self->thisBracket( $index );
	    $group->exit($_) for @$remaindered;
	    $_->floating('')            for @$remaindered;
	    $heteroBracket->entry($_)   for @$remaindered;
	if ( not $heteroBracket->{c10repaired} )
	{
	    $heteroBracket->{c10repaired} = 1;
	    my $s1 = $heteroBracket->s1;
	    my $s2 = $heteroBracket->s2;
	    my @wellpairedS2 = map { $s2->[$_] } 0..$#$s1-1;
	    my @unpairedS2 = map { $s2->[$_] } $#$s1+1..$#$s2;
	    my $lastShufflePossibility = ( $self->rank(@unpairedS2) )[-1];
	    my @lastIds = map { $_->pairingNumber }
			    @wellpairedS2, $lastShufflePossibility;
	    $heteroBracket->{lastC10Alternate} = \@lastIds;
	    my $lowest = $s1->[-1];
	    my $id = $lowest->pairingNumber;
	    my $match = $matches->[-1];
	    my $partner = $lowest->myOpponent($match);
	    my $partnerId = $partner->pairingNumber;
	    $self->log(
"Unpairing lowest downfloater, $id and $partnerId in $index-Bracket [$number]
	Returning @remaindered to $index-Bracket [$number]
	Trying different partner for $id in $index-Bracket [$number]");
	    return C7;
	}
	elsif ( $group->{lastshuffle} ) {
	    $self->log("Trying next pairing in $index-Bracket [$number]");
	    return C7;
	}
    }
    elsif ( $group->floatCheckWaive eq 'B5Down' ) {
        $group->floatCheckWaive('B6Up');
        $self->log(
"No more pairings. Dropping B6 for Upfloats in $index-Bracket [$groupNumber]");
        return C4;
    }
    elsif ( $group->floatCheckWaive eq 'B6Up' ) {
        $group->floatCheckWaive('B5Up');
        $self->log(
"No more pairings. Dropping B5 for Upfloats in $index-Bracket [$groupNumber]");
        return C4;
    }
    elsif ( $group->floatCheckWaive eq 'B5Up' ) {
        $group->floatCheckWaive('All');
        $self->log("Float checks all dropped in $index-Bracket [$groupNumber]");
        return C11;
    }
    elsif ( $group->floatCheckWaive eq 'All' ) {
        $group->floatCheckWaive('None');
        $self->log("Float checks already off in $index-Bracket [$groupNumber]");
        return C11;
    }
    #elsif ( $group->{lastshuffle} ) {
    #    $self->log(
    #        "Repairing of whole $index-Bracket [$groupNumber] failed. Go C11" );
    #    return C11;
    #}
    return ERROR, msg => "$index-Bracket [$groupNumber] fell through C10";
}


=head2 c11

 Games::Tournament::Swiss::Procedure->c11

As long as x (xprime) is less than p: increase it by 1. When pairing a remainder group undo all pairings of players moved down also. Restart at C3. (We were restarting at C7 after resetting the C7shuffler (Why?) We restart at C4 (to avoid resetting p) the 1st time, and C7 after that).
        
=cut 

sub c11 {
    my $self    = shift;
    my $brackets  = $self->brackets;
    my $index = $self->thisBracket;
    my $group   = $brackets->{ $index };
    my $number   = $group->number;
    my ($heteroBracket, @remaindered);
    my $xprime  = $group->xprime;
    my $pprime  = $group->pprime;
    my $bigGroupXprime       = $group->bigGroupXprime;
    my $bigGroupPprime       = $group->bigGroupPprime;
    if ( $group->{c11repaired} and $group->{lastheteroshuffle} )
    {
	if ( $heteroBracket = $group->{remainderof} )
	{
	    my $remaindered = $group->members;
	    @remaindered = map { $_->pairingNumber } @$remaindered;
	    $group->exit($_) for @$remaindered;
	    $_->floating('')            for @$remaindered;
	    $heteroBracket->entry($_)   for @$remaindered;
	    delete $group->{lastheteroshuffle};
	    $group->dissolved(1);
	}
	elsif ( $group->hetero ) { $heteroBracket = $group; }
	my $heteroIndex = $self->index($heteroBracket);
	$self->thisBracket( $heteroIndex );
	my $heteroNumber = $heteroBracket->number;
	my $heteroMembers = $heteroBracket->members;
	my @heteroIds = map { $_->pairingNumber } @$heteroMembers;
	$heteroIndex = $self->index($heteroBracket);
	$self->log(
"Repairing of $heteroIndex-Bracket [$heteroNumber] failed. No more pairings with X=$bigGroupXprime" );
	delete $heteroBracket->{lastheteroshuffle};
	if ( $bigGroupXprime < $bigGroupPprime ) {
	$heteroBracket->bigGroupXprime(++$bigGroupXprime);
	    $heteroBracket->{c8swapper} = $heteroBracket->c8iterator;
	    $heteroBracket->floatCheckWaive('None');
	    $self->log(
		"Retrying with X=$bigGroupXprime. All float checks on in $heteroIndex-Bracket [$heteroNumber]" );
	    return C4;
	}
	else {
	    $self->log(
	    "X=P=$bigGroupPprime, no more X increases in $index-Bracket [$number].
	    Giving up on C11 Repair. Go C12");
	    return C12;
	}
    }
    elsif ( $group->{c10repaired} ) {
	    my $matches = $self->matches->{$index};
	    delete $self->matches->{$index} if $matches;
	    $self->log( "Deleting all matches in $index-Bracket [$number]");
	    my $members = $group->members;
	    my @ids = map {$_->pairingNumber} @$members;
	    $group->bigGroupXprime(++$bigGroupXprime);
	    $group->xprime(++$xprime);
	    $group->{c10repaired} = 0;
	    $group->{lastshuffle} = 0;
	    delete $group->{lastheteroshuffle};
	    $group->{c11repaired} = 1;
	    $group->floatCheckWaive('None');
	    my $message = $group->{remainder}? "X=$bigGroupXprime": "x=$xprime";
	    $self->log(
		    "Bracket ${number}'s C11 Repairing: @ids, with $message" );
	    return C4;
    }
    elsif ( $group->{remainderof} )
    {
	if ( $group->{remainderof}->{c12repaired} )
	{
	    $self->log( "Passing to C12." );
	    return ERROR, msg => "$number($index) shouldn't pass this way";
	    return C12;
	}
	elsif ( $group->{c11repaired} )
	{
	    $heteroBracket = $group->{remainderof};
	    my $remaindered = $group->members;
	    my @remaindered = map { $_->pairingNumber } @$remaindered;
	    my $heteroNumber = $heteroBracket->number;
	    my $heteroIndex = $self->previousBracket;
	    my $heteroMembers = $heteroBracket->members;
	    my @heteroIds = map { $_->pairingNumber } @$heteroMembers;
	    # $heteroBracket->bigGroupXprime(++$bigGroupXprime);
	    $self->log(
"Repairing of @heteroIds in $heteroIndex-Bracket [$heteroNumber] failed pairing @remaindered. Trying next pairing with X=$bigGroupXprime" );
	    $group->exit($_) for @$remaindered;
	    $_->floating('')            for @$remaindered;
	    $heteroBracket->entry($_)   for @$remaindered;
	    $group->dissolved(1);
	    $self->thisBracket( $heteroIndex );
	    return C7;
	}
    }
    elsif ( $xprime < $pprime ) {
	$group->xprime(++$xprime);
        $self->log( "x=$xprime" );
        if ( $group->{remainder} )
        {
	    $heteroBracket = $group;
            delete $self->matches->{$index};
            $self->log("Undoing all hetero $index-Bracket [$number] matches.");
	    $self->log( "All float checks on in $index-Bracket [$number]" );
	    $heteroBracket->floatCheckWaive('None');
	    $heteroBracket->resetShuffler;
	    return C7;
        }
	else {
	    $group->{c8swapper} = $group->c8iterator;
	    $group->floatCheckWaive('None');
	    $self->log( "All float checks on in $index-Bracket [$number]" );
	    return C4;
	}
    }
    else {
	$self->log(
         "x=p=$bigGroupPprime, no more x increases in $index-Bracket [$number]" );
	return C12;
    }
    return ERROR, msg => "$number($index) fell through C11", pairing => $self;
}


=head2 c12

 Games::Tournament::Swiss::Procedure->c12

If the group contains a player who cannot be paired without violating B1 or B2 and this is a heterogeneous group, undo the pairing of the previous score bracket. If in this previous score bracket a pairing can be made whereby another player will be moved down to the current one, and this now allows p pairing to be made then this pairing in the previous score bracket will be accepted. (If there was only one (or two) players in the previous score bracket, obviously (heh-heh) there is no use going back and trying to find another pairing). Using a c12repaired flag to tell if this is the 2nd time through (but what if this is a backtrack to a different bracket?).
 
=cut 

sub c12 {
    my $self   = shift;
    my $brackets = $self->brackets;
    my $index = $self->thisBracket;
    my $group = $brackets->{$index};
    my $number  = $group->number;
    my $first = $self->firstBracket;
    if ( $index eq $first )
    {  
	$self->log( "No C12 repair from first $index-Bracket [$number]" );
	return C13;
    }
    my $prevIndex = $self->previousBracket;
    my $previous = $brackets->{$prevIndex};
    my $prevNumber = $previous->number;
    my $previousMembers = $previous->members;
    if ( $group->{c12repaired} or $previous->{c12repaired} )
    {
	$self->log(
"Repairing of $prevIndex-Bracket [$prevNumber] failed to pair $index [$number]. Go to C13");
	return C13;
    }
    elsif ( $group->{c11repaired} )
    {
        if (not $previous->{c12repaired}) {
	    my @downfloaters = $group->downFloaters;
	    my @floatIds = map { $_->pairingNumber } @downfloaters;
	    my $score = $previous->score;
	    my $matches = $self->matches->{$prevIndex};
	    delete $self->matches->{$prevIndex} if $matches;
	    $self->log(
"Deleting matches in $prevIndex-Bracket [$prevNumber], home of @floatIds");
	    my $paired = $previous->members;
	    my @ids = map {$_->pairingNumber} @downfloaters, @$paired;
	    $self->log(
		"$prevIndex-Bracket [$prevNumber] C12 Repairing: @ids");
	    $group->exit($_) for @downfloaters;
	    $_->floating('')            for @downfloaters;
	    $previous->entry($_) for @downfloaters;
	    $previous->{c12repaired} = 1;
	    $previous->floatCheckWaive('None');
	    $previous->{c8swapper} = $previous->c8iterator;
	    $previous->resetS12;
	    my $s2 = $previous->s2;
	    $self->thisBracket($prevIndex);
	    return C7;
        }
    }
    elsif ( $group->{remainderof} and $group->{remainderof}->{c12repaired} )
    {
	my $repairGroupIndex = $self->previousBracket;
	my $heteroBracket = $group->{remainderof};
	my $repairGroupNumber = $heteroBracket->number;
	my $c11RepairRemainder = $group;
	    $self->log( "No repairings in $repairGroupNumber. Go to C13." );
	    return C13;
    }
    elsif ( $group->{remainderof} and $group->{remainderof}->{c11repaired} )
    {
	my $c11Remainder = $group;
	my $c11RepairIndex = $prevIndex;
	my $c11RepairGroup = $previous;
	my $c11RepairNumber = $prevNumber;
	my $paired = $previousMembers;
	my $score = $c11RepairGroup->score;
	my @ids = map {$_->pairingNumber} @$paired;
	my $matches = $self->matches;
	delete $matches->{ $c11RepairIndex };
	delete $matches->{$c11Remainder} if $matches->{$c11Remainder};
	$self->log(
    "Undoing Bracket $c11RepairIndex-Bracket ($c11RepairNumber) pairs, @ids.");
	$self->thisBracket($c11RepairIndex);
	my $remainderMembers = $c11Remainder->members;
	$c11Remainder->exit($_) for @$remainderMembers;
	$_->floating('')            for @$remainderMembers;
	$c11RepairGroup->entry($_) for @$remainderMembers;
	$c11Remainder->dissolved(1);
	$self->log( "Dissolving $c11RepairIndex-Bracket's Remainder Group" );
	my $newPrevIndex = $self->previousBracket;
	my $bracketAbove = $brackets->{$newPrevIndex};
	my $aboveNumber = $bracketAbove->number;
	if ( $bracketAbove and $bracketAbove->hetero )
	{
	    my $key = $score . "C12Repair";
	    my $c12RepairGroup = Games::Tournament::Swiss::Bracket->new(
	    score       => $score,
	    c12repaired => 1,
	    c12down => $c11RepairGroup,
	    number      => "$aboveNumber(post-C12)"
	    );
	    my @downfloaters = $c11RepairGroup->downFloaters;
	    $c11RepairGroup->exit($_) for @downfloaters;
	    $_->floating('')            for @downfloaters;
	    $c12RepairGroup->entry($_) for @downfloaters;
	    $c11RepairGroup->{c12up} = $c12RepairGroup;
	    my @floatIds = map {$_->pairingNumber} @downfloaters;
	    my @prevIds = map {$_->pairingNumber} @{$c12RepairGroup->members};
	    my @thisIds = map {$_->pairingNumber} @{$group->members};
	    $self->log("C12 Repairing of previous $newPrevIndex-Bracket");
	    $self->log(qq/Unfloating @floatIds back from $number ($index). /);
	    $self->log(
		"$index-Bracket [$number]: @thisIds & [$prevNumber]: @prevIds");
	    $bracketAbove->dissolved(1);
	    $c12RepairGroup->floatCheckWaive('None');
	    $c12RepairGroup->{c8swapper} = $c12RepairGroup->c8iterator;
	    $c12RepairGroup->resetS12;
	    $brackets->{$key} = $c12RepairGroup;
	    $self->thisBracket($key);
	    return C7;
	}
	elsif ( not $bracketAbove->hetero ) {
	    $self->log(
    "No C11 OR C12 repairings of $c11RepairIndex-Bracket ($c11RepairNumber)");
	    return C13;
	}
    }
    elsif ( $group->hetero )
    {
	my @downfloaters = $group->downFloaters;
	my $floaterSourceIndex = $prevIndex;
	my $floaterSource = $previous;
	my $floaterSourceNumber = $prevNumber;
	my $paired = $floaterSource->members;
	my $score = $floaterSource->score;
	my @ids = map {$_->pairingNumber} @$paired;
	my $matches = $self->matches;
	delete $matches->{ $prevIndex };
	$self->log(
    "Undoing Bracket $floaterSourceNumber($floaterSourceIndex) pairs, @ids.");
	my $key = $score . "C12Repair";
	my $c12RepairGroup = Games::Tournament::Swiss::Bracket->new(
	score       => $score,
	c12repaired => 1,
	c12down => $group,
	number      => "$floaterSourceNumber(post-C12)"
	);
	$group->exit($_) for @downfloaters;
	$group->c8swapper('');
	$floaterSource->exit($_) for @$paired;
	$_->floating('')            for @downfloaters;
	$c12RepairGroup->entry($_) for @downfloaters, @$paired;
	$floaterSource->{c12repair} = $c12RepairGroup;
	$group->{c12up} = $c12RepairGroup;
	my @floatIds = map {$_->pairingNumber} @downfloaters;
	my @prevIds = map {$_->pairingNumber} @{$c12RepairGroup->members};
	my @thisIds = map {$_->pairingNumber} @{$group->members};
	$self->log(qq/Unfloating @floatIds back from $number ($index). /);
	$self->log("[$number]: @thisIds & [$prevNumber]: @prevIds");
	$floaterSource->dissolved(1);
	$c12RepairGroup->floatCheckWaive('None');
	$c12RepairGroup->{c8swapper} = $c12RepairGroup->c8iterator;
	$c12RepairGroup->resetS12;
	my $s2 = $c12RepairGroup->s2;
	$c12RepairGroup->badpair($#$s2);
	$brackets->{$key} = $c12RepairGroup;
	$self->thisBracket($key);
	return C7;
    }
    elsif ( not $group->hetero )
    {
	$self->log(
	    "$index-Bracket [$number] not heterogeneous. Passing to C13.");
	return C13;
    }
    return ERROR, msg => "$index-Bracket [$number] fell through C12";
}


=head2 c13

 Games::Tournament::Swiss::Procedure->c13

If the lowest score group contains a player who cannot be paired without violating B1 or B2 or who, if they are the only player in the group, cannot be given a bye (B1b), the pairing of the penultimate score bracket is undone.  Try to find another pairing in the penultimate score bracket which will allow a pairing in the lowest score bracket. If in the penultimate score bracket p becomes zero (i.e. no pairing can be found which will allow a correct pairing for the lowest score bracket) then the two lowest score brackets are joined into a new lowest score bracket. Because now another score bracket is the penultimate one C13 can be repeated until an acceptable pairing is obtained.  XXX  Perhaps all the players from the old penultimate bracket were floated down. eg, t/cc6619.t. As a hack unfloat only those with the same score as the new penultimate bracket.

TODO not finding a pairing is not a program ERROR, but a LAST state.

=cut 

sub c13 {
    my $self    = shift;
    my $brackets  = $self->brackets;
    my $matches = $self->matches;
    my $index = $self->thisBracket;
    my $group   = $brackets->{$index};
    my $number   = $group->number;
    my $members = $group->members;
    unless ($index eq $self->lastBracket) {
       $self->log("$index-Bracket [$number] not last group. Passing to C14" ) ;
       return C14;
    }
    if ( $index eq $self->firstBracket )
    {
	return LAST,
	msg => "All joined into one $index bracket, but no pairings! Sorry";
    }
    if ( @$members == 1 ) {
	my $lastone = $members->[0];
	my $pairingN = $lastone->pairingNumber;
	my $id = $lastone->id;
	$self->log( "One unpaired player, $pairingN in last bracket $number." );
	my $byeGone = $self->byes->{$id};
	if ( not $byeGone) {
	    $self->byer($lastone);
	    return BYE;
	}
	$self->log( "B1b: But that player, id $id had Bye in round $byeGone." );
    }
    my $penultimateIndex = $self->previousBracket;
    my $penultimateBracket = $brackets->{$penultimateIndex};
    my $penultimateNumber = $penultimateBracket->number;
    my $penultScore = $penultimateBracket->score;
    # $penultimateBracket->floatCheckWaive('None');
    delete $matches->{ $penultimateIndex };
    $self->log(
	"Undoing $penultimateIndex-Bracket [$penultimateNumber] matches");
    my @returnees = grep { $_->score == $penultScore } @$members;
    if ( @returnees )
    {   
	my @floaterIds = map { $_->pairingNumber } @returnees;
	$self->log( "Unfloating @floaterIds back from $number." );
	$group->exit($_) for @returnees;
	$_->floating('')            for @returnees;
	$penultimateBracket->entry($_)   for @returnees;
	$_->floating('') for ( $penultimateBracket->upFloaters );
	$penultimateBracket->resetShuffler;
	$brackets->{ $index } = $group;
    }
    my $penultp       = $penultimateBracket->p;
    my $penultxPrime       = $penultimateBracket->xprime;
    my $penultpPrime  = $penultimateBracket->pprime;
    if ($penultpPrime and not @returnees) {
        $penultpPrime -= 1;
        $penultxPrime -= 1 if $penultxPrime;
    }
    $penultimateBracket->pprime($penultpPrime);
    $penultimateBracket->xprime($penultxPrime);
    $self->log( "penultimate p=$penultpPrime." );
    if ( $penultpPrime == 0 ) {
	my $evacuees = $penultimateBracket->members;
	my @evacuIds = map { $_->pairingNumber } @$evacuees;
	$penultimateBracket->exit($_) for @$evacuees;
	$_->floating('Down') for @$evacuees;
	$group->entry($_) for @$evacuees;
	$penultimateBracket->dissolved(1);
	my @finalIds = map { $_->pairingNumber } @$members;
	my @penultimateIds = map { $_->pairingNumber }
			    @{$penultimateBracket->members};
        $self->log( "Joining Bracket $penultimateNumber, $number." );
        $self->log( "[$penultimateNumber] @evacuIds => [$number] @finalIds" );
	$group->resetShuffler;
        return C1;
    }
    if ( $penultpPrime > 0 ) {
	    my @penultids = map {$_->pairingNumber}
				    @{$penultimateBracket->members};
	my @finalids = map {$_->pairingNumber} @{$group->members};
        $self->log( "Re-pairing Bracket $penultimateNumber." );
        $self->log( "[$penultimateNumber]: @penultids & [$number]: @finalids" );
	my $s2 = $penultimateBracket->s2;
	$penultimateBracket->badpair($#$s2);
	$self->thisBracket($penultimateIndex);
	$self->penultpPrime( $penultpPrime );
        return C7;
    }
    else { return ERROR, msg => "Fell through C13 in $number ($index)"; }
}


=head2 bye

 $self->bye

The last, singular, unpairable player is given a bye. B2

=cut 

sub bye {
    my $self = shift;
    my $index = $self->thisBracket;
    my $brackets = $self->brackets;
    my $bracket = $brackets->{$index};
    my $members = $bracket->members;
    my $byer = $self->byer;
    my $id = $byer->id;
    my $byes = $self->byes;
    my $round = $self->round;
    my $matches = $self->matches;
    my $byeindex = $index =~ /Bye$/? $index : $index . 'Bye';
    my $game = 
      Games::Tournament::Card->new(
	round       => $round,
	result      => undef,
	contestants => { Bye => $byer } );
    $game->float($byer, 'Down');
    $matches->{$byeindex} = [ $game ];
    $self->log( "OK." );
    $byes->{$id} = $round;
    return LAST;
}




=head2 c14

 Games::Tournament::Swiss::Procedure->c14

Decrease p (pprime) by 1 (and if the original value of x was greater than zero decrease x by 1 as well). As long as p is unequal to zero restart at C4. (At C13, if this is final bracket, because this means it is unpairable.) If p equals zero the entire score bracket is moved down to the next one. Restart with this score bracket at C1. (If it is the penultimate bracket, and the final bracket is unpairable, the final bracket is moved up, but I guess that's the same thing. C13 )

=cut 

sub c14 {
    my $self   = shift;
    my $groups = $self->brackets;
    my $index = $self->thisBracket;
    my $group   = $groups->{ $index };
    my $number  = $group->number;
    my $members = $group->members;
    my $p       = $group->p;
    my $x       = $group->xprime;
    my $pprime  = $group->pprime;
    if ($pprime) {
        $pprime -= 1;
        $x -= 1 if $x;
    }
    $group->pprime($pprime);
    $group->xprime($x);
    $group->floatCheckWaive('None');
    $self->log( "Bracket $number, now p=$pprime" );
    my $next = $self->nextBracket;
    my $nextgroup = $groups->{$next};
    if ( $pprime == 0 and $index eq $self->lastBracket and defined
						    $self->penultpPrime ) {
	$self->penultpPrime(undef);
	$self->previousBracket($group);
	return C13;
    }
    elsif ( $pprime < $p and $index eq $self->lastBracket )
    {
	$self->penultpPrime(undef);
        return C13;
    }
    elsif ($pprime > 0) 
    {
	$self->log( "Trying to pair Bracket $index ($number) again" );
	return C4;
    }
    elsif ( $nextgroup->{remainderof} )
    {
	my $returners = $nextgroup->members;
        $nextgroup->exit($_)  for @$returners;
        $_->floating('')           for @$returners;
        $group->entry($_)      for @$returners;
	$group->naturalize($_) for @$returners;
	my $remainderNumber = $nextgroup->number;
	my @remainderIds = map { $_->pairingNumber } @$returners;
	my @heteroIds = map { $_->pairingNumber } @{$group->members};
        $self->log( "Moving all Group $remainderNumber members back to $number." );
        $self->log( "@remainderIds => Bracket $number: @heteroIds" );
	$self->thisBracket($index);
	$nextgroup->resetShuffler;
	$nextgroup->dissolved(1);
        return C1;
    }
    else {
	my @evacuees = @$members;
        $group->exit($_)  for @evacuees;
        $_->floating('Down')           for @evacuees;
        $nextgroup->entry($_)      for @evacuees;
	$nextgroup->naturalize($_) for @evacuees;
	my $nextNumber = $nextgroup->number;
	my @thisMemberIds = map { $_->pairingNumber } @evacuees;
	my @nextMemberIds = map { $_->pairingNumber } @{$nextgroup->members};
        $self->log( "Moving down all Bracket $number($next), to $nextNumber." );
        $self->log( "@thisMemberIds => Bracket $nextNumber: @nextMemberIds" );
	$self->thisBracket($next);
	$nextgroup->resetShuffler;
	$group->dissolved(1);
        return C1;
    }
}


=head2 colors

	$next = $pairing->c7
	while ( my @s2 = &$next )
	{
	    create match cards unless this permutation is incompatible;
	}

After an acceptable pairing is achieved that doesn't violate the one-time match only principle (B1) and the 2-game maximum on difference between play in one role over that in the other role (B2), roles are allocated so as to grant the preferences of both players, or grant the stronger preference, or grant the opposite roles to those they had when they last played a round in different roles, or grant the preference of the higher ranked player, in that order. (E) A Games::Tournament::Card object, records round, contestants, (undefined) result, and floats (A4).
 

=cut 

sub colors {
    my $self       = shift;
    my %args       = @_;
    my $groups     = $self->brackets;
    my $round      = $self->round;
    my $thisGroup = $self->thisBracket;
    my $group = $groups->{$thisGroup};
    my $number      = $group->number;
    my $pairs = $args{paired};
    my ($message, @bracketMatches);
    for my $pair ( @$pairs ) {
        my @pair = @$pair;
        my @rolehistory = ( map { $pair[$_]->rolesPlayedList } 0, 1 );
	my @lastdiff;
	for my $lookback ( 1 .. $round - FIRSTROUND )
	{
	    last if notall { $_->firstround <= $round-$lookback } @pair;
	    my $s1role = $rolehistory[0]->[-$lookback];
	    my $s2role = $rolehistory[1]->[-$lookback];
	    my @ids = map {$_->id} @pair;
	    # die "Missing roles for Players @ids in Round " . ($round-$lookback)
	    last
	    		    unless $s1role and $s2role;
	    next if $s1role eq $s2role;
            next unless 2 == grep { $_ eq (ROLES)[0] or $_ eq (ROLES)[1] }
		    ($s1role, $s2role);
	    @lastdiff = ($s1role, $s2role);
	    last;
	}
        my ( $contestants, $stronger, $diff );
        my @roles     = map { $_->preference->role } @pair;
        my @strengths = map { $_->preference->strength } @pair;
        my $rule;
        if ( not $roles[0] and not $roles[1] ) {
            ( $roles[0], $roles[1] ) = $self->randomRole;
            $rule = 'No prefs';
        }
        if ( not $roles[0] ) {
            $roles[0] =
                ( $roles[1] eq (ROLES)[1] )
              ? (ROLES)[0]
              : (ROLES)[1];
            $rule = 'No S1 pref';
        }
        if ( not $roles[1] ) {
            $roles[1] =
                ( $roles[0] eq (ROLES)[1] )
              ? (ROLES)[0]
              : (ROLES)[1];
            $rule = 'No S2 pref';
        }
        if ( $roles[0] ne $roles[1] ) {
            $contestants = { $roles[0] => $pair[0], $roles[1] => $pair[1] };
            $rule = 'E1';
        }
        elsif ( $strengths[0] ne $strengths[1] ) {
            if (
                defined(
                    $stronger = (
                        grep { $pair[$_]->preference->strength eq 'Absolute' }
                          0 .. 1
                      )[0]
                )
              )
            {
                1;
            }
            elsif (
                defined(
                    $stronger = (
                        grep { $pair[$_]->preference->strength eq 'Strong' }
                          0 .. 1
                      )[0]
                )
              )
            {
                1;
            }
            elsif (
                defined(
                    $stronger = (
                        grep { $pair[$_]->preference->strength eq 'Mild' }
                          0 .. 1
                      )[0]
                )
              )
            {
                1;
            }
            my $strongerRole = $pair[$stronger]->preference->role;
            my $weaker       = $stronger == 0 ? 1 : 0;
            my $weakerRole   = ( grep { $_ ne $strongerRole } ROLES )[0];
            $contestants = {
                $strongerRole => $pair[$stronger],
                $weakerRole   => $pair[$weaker]
            };
            $rule = 'E2';
        }
        elsif ( @lastdiff )
        {
            $contestants = {$lastdiff[1] => $pair[0], $lastdiff[0] => $pair[1]};
            $rule = 'E3';
        }
        else {
            my $rankerRole = $pair[0]->preference->role;
            my $otherRole = ( grep { $_ ne $rankerRole } ROLES )[0];
            $contestants = { $rankerRole => $pair[0], $otherRole => $pair[1] };
            $rule = 'E4';
        }
        $message .=  $rule . ' ' .
	    $contestants->{ (ROLES)[0] }->pairingNumber . "&" .
	    $contestants->{ (ROLES)[1] }->pairingNumber . ' ';
        my $game = Games::Tournament::Card->new(
            round       => $self->round,
            result      => undef,
            contestants => $contestants,
          );
	$game->float($contestants->{$_}, $contestants->{$_}->floating || 'Not')
			    for ROLES;
        push @bracketMatches, $game;
    }
    # $self->previousBracket($group);
    return $message, @bracketMatches;
}


=head2 brackets

	$pairing->brackets

Gets/sets all the brackets which we are pairing. The order of this array is important. The brackets are paired in order. I was storing these as an anonymous array of score group (bracket) objects. But the problem of remainder groups has forced me to store as a hash.

=cut

sub brackets {
    my $self     = shift;
    my $brackets = shift;
    if ( defined $brackets ) { $self->{brackets} = $brackets; }
    elsif ( $self->{brackets} ) { return $self->{brackets}; }
}


=head2 bracketOrder

	$pairing->bracketOrder

Gets an array of homogeneous and heterogeneous brackets in order with remainder groups (iff they have been given bracket status and only until this status is withdrawn) coming after the heterogeneous groups from which they are formed. This ordered array is necessary, because remainder groups come into being and it is difficult to move back to them. Do we re-pair the remainder group, or the whole group from which it came? Remember to keep control of remainder groups' virtual bracket status with the dissolved field. This method depends on each bracket having an index made up of the bracket score and a 'Remainder' or other appropriate suffix, if it is a remainder or other kind of sub-bracket. We rely on the lexico ordering of the suffixes.

TODO No need to create scoresAndTags list of lists here. Just do 
    @index{@indexes} = map {  m/^(\d*\.?\d+)(\D.*)?$/;
		{score => $1, tag => $2||'' }
		} @indexes;

=cut

sub bracketOrder {
    my $self     = shift;
    my $brackets = $self->brackets;
    my @indexes = grep { not $brackets->{$_}->dissolved } keys %$brackets;
    my @scoresAndTags = map { m/^(\d*\.?\d+)(\D.*)?$/; [$1,$2] } @indexes;
    my %index;
    @index{@indexes} = map {{score => $_->[0], tag => $_->[1] || '' }} 
				@scoresAndTags;
    my @indexOrder = sort { $index{$b}->{score} <=> $index{$a}->{score} ||
			$index{$a}->{tag} cmp $index{$b}->{tag} }
				@indexes;
    unshift @indexOrder, 'START';
    return @indexOrder;
}


=head2 firstBracket

	$pairing->firstBracket

Gets the firstBracket. This is the undissolved bracket with the highest score.

=cut

sub firstBracket {
    my $self     = shift;
    my @scoreOrder = $self->bracketOrder;
    my $startBlock = shift @scoreOrder;
    my $firstBracket = shift @scoreOrder;
    return $firstBracket;
}


=head2 lastBracket

	$pairing->lastBracket

Gets the lastBracket. With the joining of score brackets and addition of remainder groups, this bracket may change.

=cut

sub lastBracket {
    my $self     = shift;
    my @scoreOrder = $self->bracketOrder;
    return pop @scoreOrder;
}


=head2 nextBracket

	$pairing->nextBracket

Gets the nextBracket to that which we are pairing now. This may or may not be a remainder group, depending on whether they have been given virtual bracket status.

=cut

sub nextBracket {
    my $self     = shift;
    my $place = $self->thisBracket;
    my @scoreOrder = $self->bracketOrder;
    my $nextBracket;
    if (defined $place)
    {
	my $next = 0;
	for my $index ( @scoreOrder ) {
		$nextBracket = $index;
		last if $next;
		$next++ if $index eq $place;
	    }
	return $nextBracket unless $nextBracket eq $place;
    }
    return;
}


=head2 previousBracket

	$pairing->previousBracket

Gets the previousBracket to that which we are pairing now. This may or may not be a remainder group, depending on whether they have been given virtual bracket status.

=cut

sub previousBracket {
    my $self     = shift;
    my $place = $self->thisBracket;
    my @indexOrder = $self->bracketOrder;
    my $previousBracket;
    for my $index ( @indexOrder ) {
	last if $index eq $place;
	$previousBracket = $index;
    }
    return $previousBracket;
}


=head2 index

	$pairing->index($bracket)

Gets the index of $bracket, possibly a changing label, because remainder groups coming into being and are given virtual bracket status.

=cut

sub index {
    my $self     = shift;
    my $brackets = $self->brackets;
    my $bracket = shift;
    my $score = $bracket->score;
    my $number = $bracket->number;
    my @order = $self->bracketOrder;
    my $index = first { m/^\d+(\.5)?$/ and $brackets->{$_}->score==$score }
					    @order;
    confess "No index for Bracket $number, with score $score. Is it dissolved?"
				    unless defined $index;
    # $index .= 'C11Repair' if $bracket->{c11repairof};
    # $index .= 'C10Repair' if $bracket->{c10repairof};
    $index .= 'Remainder' if $bracket->{remainderof};
    return $index;
}


=head2 round

	$pairing->round

What round is this round's results we're pairing on the basis of?

=cut

sub round {
    my $self  = shift;
    my $round = shift;
    if ( defined $round ) { $self->{round} = $round; }
    elsif ( $self->{round} ) { return $self->{round}; }
}


=head2 thisBracket

	$pairing->thisBracket
	$pairing->thisBracket($pairing->firstBracket)

What bracket is this? Gets/sets a string of the form $score, or
${score}Remainder if it is a remainder group. (In C10, create an 'C10Repair' group.) You need to set this when moving from one bracket to another. And test the value returned. If no bracket is set, undef is returned.

=cut

sub thisBracket {
    my $self  = shift;
    my $thisBracket = shift;
    if ( defined $thisBracket ) { $self->{thisBracket} = $thisBracket; }
    elsif ( defined $self->{thisBracket} ) { return $self->{thisBracket}; }
    return;
}


=head2 byer

	$group->byer

Gets/sets the player set to take the bye.

=cut

sub byer {
    my $self    = shift;
    my $byer = shift;
    if ( defined $byer ) { $self->{byer} = $byer; }
    elsif ( $self->{byer} ) { return $self->{byer}; }
    return;
}


=head2 paired

	$group->paired

Gets/sets an array of paired players, arranged pair by pair, in the bracket being paired.

=cut

sub paired {
    my $self    = shift;
    my $paired = shift;
    if ( defined $paired ) { $self->{paired} = $paired; }
    elsif ( $self->{paired} ) { return $self->{paired}; }
    return;
}


=head2 nonpaired

	$group->nonpaired

Gets/sets an array of nonpaired players in the bracket being paired.

=cut

sub nonpaired {
    my $self    = shift;
    my $nonpaired = shift;
    if ( defined $nonpaired ) { $self->{nonpaired} = $nonpaired; }
    elsif ( $self->{nonpaired} ) { return $self->{nonpaired}; }
    return;
}


=head2 matches

	$group->matches

Gets/sets the matches which we have made. Returned is an anonymous hash of the matches in the round, keyed on a bracket index. Each value of the hash is an anonymous array of the matches in that bracket. So to get each actual match, you need to break up the matches in the individual brackets.

=cut

sub matches {
    my $self    = shift;
    my $matches = shift;
    if ( defined $matches ) { $self->{matches} = $matches; }
    elsif ( $self->{matches} ) { return $self->{matches}; }
    return;
}


=head2 whoPlayedWho

	$group->whoPlayedWho

Gets/sets a anonymous hash, keyed on the pairing numbers of the opponents, of the preference of individual pairs of @grandmasters, if they both have the same absolute preference, and so can't play each other. This has probably been calculated by Games::Tournament::Swiss::whoPlayedWho B1a

=cut

sub whoPlayedWho {
    my $self         = shift;
    my $whoPlayedWho = shift;
    if ( defined $whoPlayedWho ) { $self->{whoPlayedWho} = $whoPlayedWho; }
    elsif ( $self->{whoPlayedWho} ) { return $self->{whoPlayedWho}; }
}


=head2 colorClashes

	$group->colorClashes

Gets/sets a anonymous hash, keyed on the pairing numbers of the opponents, of their preference, if (and only if) they both have an Absolute preference for the same role and so can't play each other. This has probably been calculated by Games::Tournament::Swiss::colorClashes B2a

=cut

sub colorClashes {
    my $self         = shift;
    my $colorClashes = shift;
    if ( defined $colorClashes ) { $self->{colorClashes} = $colorClashes; }
    elsif ( $self->{colorClashes} ) { return $self->{colorClashes}; }
}


=head2 incompatibles

	$group->incompatibles

Gets/sets a anonymous hash, keyed on the pairing numbers of the opponents, of a previous round in which individual pairs of @grandmasters, if any, met. Or of their preference if they both have an Absolute preference for the same role and can't play each other. This has probably been calculated by Games::Tournament::Swiss::incompatibles. B1

=cut

sub incompatibles {
    my $self          = shift;
    my $incompatibles = shift;
    if ( defined $incompatibles ) { $self->{incompatibles} = $incompatibles; }
    elsif ( $self->{incompatibles} ) { return $self->{incompatibles}; }
}


=head2 byes

	$group->byes
	return BYE unless $group->byes->{$id}

Gets/sets a anonymous hash, keyed on ids, not pairing numbers of players, of a previous round in which these players had a bye. This has probably been calculated by Games::Tournament::Swiss::byes. B1

=cut

sub byes {
    my $self = shift;
    my $byes = shift;
    if ( defined $byes ) { $self->{byes} = $byes; }
    elsif ( $self->{byes} ) { return $self->{byes}; }
}


=head2 penultpPrime

	$pairing->penultpPrime
	$pairing->penultpPrime($previousBracket->pprime)

Gets/sets an accessor to the number of pairs in the penultimate bracket. When this reaches 0, the penultimate and final brackets are joined. C14

=cut

sub penultpPrime {
    my $self = shift;
    my $penultpPrime = shift;
    if ( defined $penultpPrime ) { $self->{penultpPrime} = $penultpPrime; }
    elsif ( $self->{penultpPrime} ) { return $self->{penultpPrime}; }
    return;
}


=head2 floatCriteriaInForce

	$group->floatCriteriaInForce( $group->floatCheckWaive )

Given the last criterion at which level checks have been waived, returns an anonymous array of the levels below this level for which checking is still in force. B5,6 C6,9,10 TODO All is nice, but creates problems.

=cut

sub floatCriteriaInForce {
    my $self = shift;
    my $level = shift;
    my @levels = qw/None B6Down B5Down B6Up B5Up All None/;
    my $oldLevel = '';
    $oldLevel = shift @levels until $oldLevel eq $level;
    return \@levels;
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

1;    # End of Games::Tournament::Swiss::Procedure

# vim: set ts=8 sts=4 sw=4 noet:
