=head1 NAME

Game::Object::Worm::Bot - Worm

=head1 SYNOPSIS

Nah...

=cut





package Game::Object::Worm::Bot;
use base qw( Game::Object::Worm );





use strict;
use Data::Dumper;
use Carp qw( confess );





=head1 PROPERTIES

=head2 isRealPlayer

Whether this is a real life player or not.

Default: 0

=cut





=head2 probabilityTurnRandomly

The probability (0..1) that the Worm will turn randomly for 
every move forward.

Default: 0 (no turning)

=cut
use Class::MethodMaker get_set => [ "probabilityTurnRandomly" ];





=head2 probabilityTurnTowardsPrize

The probability (0..1) that the Worm will turn towards a 
prize when it's on the same line.

Default: 0 (no turning)

=cut
use Class::MethodMaker get_set => [ "probabilityTurnTowardsPrize" ];





=head1 METHODS

=head2 new([$left = 11], [$top = 12], [$direction = "left"], [$length = 3)

Create new Bot Worm, facing in $direction ("left", "right",
"up", "down" (only left supported right now)), with a body a
total size of $length.

=cut
sub new { my $pkg = shift;
    my ($left, $top, $direction, $length) = @_;

    my $self = $pkg->SUPER::new($left, $top, $direction, $length);
    $self->isRealPlayer(0);
    $self->color("red");
    $self->probabilityTurnRandomly(0);
    $self->probabilityTurnTowardsPrize(0);

    return($self);
}





=head2 cloneValuesFrom($oObject)

Clone important values (like probabilities etc, not location 
and direction etc.) from $oObject into $self.

Return 1.

=cut
sub cloneValuesFrom { my $self = shift;    
    my ($oObject) = @_;
    
    $self->oEventMove->timeInterval( $oObject->oEventMove->timeInterval );
    $self->probabilityTurnRandomly( $oObject->probabilityTurnRandomly );
    $self->probabilityTurnTowardsPrize( $oObject->probabilityTurnTowardsPrize );
    
    return(1);
}





=head2 moveForward()

#Possibly turn left/right (percentChanceTurn() chance that
#will happen).

Move forward one step in the oDirection. If that's not
possible, try to turn left or right. If that's not possible,
fail.

Return 1 on success, else 0.

=cut
sub moveForward { my $self = shift;

    #Attempt to move normally
    if($self->SUPER::moveForward()) {
        $self->possiblyTurnTowardsPrize() and return(1);
        $self->possiblyTurnRandomly();
        return(1);
        }

    #Nope, not possible, turn
    my $direction = $self->randomDirection();
    $self->oDirection->turn($direction);

    #Move
    $self->SUPER::moveForward() and return(1);
    
    #Nope, failed too! Turn other way and try a last time
    $direction = $self->oppositeDirection($direction);
    $self->oDirection->turn($direction);
    $self->oDirection->turn($direction);
    
    return( $self->SUPER::moveForward() );        #If it fails here too, the move fails
}





=head2 randomDirection()

Return "left" or "right", randomly.

=cut
my $rhDirection = {
    0 => "left",
    1 => "right",
    };
sub randomDirection { my $self = shift;

    my $dirIndex = int(rand(2));
    my $direction = $rhDirection->{$dirIndex} or die("Programmer error: Could not randomly select left/right ($dirIndex)");
    
    return($direction);
}





=head2 oppositeDirection($direction)

Return the opposite of $direction ("left" or "right").

=cut
my $rhDirectionOpposite = {
    "right" => "left",
    "left" => "right",
    };
sub oppositeDirection { my $self = shift;
    my ($direction) = @_;

    $direction = $rhDirectionOpposite->{$direction} or confess("Invalid direction($direction)");
    
    return($direction);
}





=head2 possiblyTurnRandomly()

If probabilityTurnRandomly(), turn left/right

Return the turned direction ("left"/"right") or "" if no 
turn was made.

=cut
sub possiblyTurnRandomly { my $self = shift;

    if((rand() + .0001) < $self->probabilityTurnRandomly) {        #0.0001 to come above 0, so we can have a 0% chanse of turning
        $self->oDirection->turn( my $direction = $self->randomDirection() );

        #If this turn puts us into a wall the next move, it's not worth it, turn back
        if(! $self->oValidLocationAfterMove()) {
            $direction = $self->oppositeDirection($direction);
            $self->oDirection->turn($direction);
            return("");
            }
        
        return($direction);
        }
    
    return("");
}





=head2 possiblyTurnTowardsPrize()

If probabilityTurnTowardsPrize(), turn left/right

Return the turned direction ("left"/"right") or "" if no 
turn was made.

=cut
sub possiblyTurnTowardsPrize { my $self = shift;

    #The rand is the least expensive here, do that first
    if((rand() + .0001) < $self->probabilityTurnTowardsPrize) {        #0.0001 to come above 0, so we can have a 0% chanse of turning
    
        #Find a Prize
        $self->oLawn or return("");        
        my $oDirection = $self->oLawn->oDirectionToPrize( $self->oLocation ) or return("");
        
        #Find a turn
        my $direction = $self->oDirection->turnDifference($oDirection) or return("");
        
        #Turn
        $self->oDirection->turn($direction);

        #If this turn puts us into a wall the next move, it's not worth it, turn back
        if(! $self->oValidLocationAfterMove()) {
            $direction = $self->oppositeDirection($direction);
            $self->oDirection->turn($direction);
            return("");
            }
        
        return($direction);
        }
    
    return("");
}





1;





#EOF
