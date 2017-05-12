=head1 NAME

Game::Object::Worm - Worm

=head1 SYNOPSIS

Nah...

=cut





package Game::Object::Worm;
use base qw( Game::Object Game::Direction );







use strict;


use Data::Dumper;
use Game::Location;
use Game::Direction;
use Game::Event::Timed;






=head1 STUFF

=over 4

=item ExceptionCouldNotMoveForward

Thrown when the Worm could not moveForward().

    oObject - $self


=cut
use Exception::Class (
    'Exception',

    'ExceptionCouldNotMoveForward' => {
        isa => 'Exception',
        fields => [ 'oObject', ],
    },
);


=pod

=back

=cut



=head1 PROPERTIES

=head2 isRealPlayer

Whether this is a real life player or not.

Default: 1

=cut
use Class::MethodMaker get_set => [ "isRealPlayer" ];





=head2 oDirection($direction)

Game::Direction object.

=cut
use Class::MethodMaker get_set => [ "oDirection" ];





=head2 $self->oEventMove

Timed event for movement.

Default: interval 0.2

=cut
use Class::MethodMaker get_set => [ "oEventMove" ];





=head2 $self->score( ... args ... );

The accumulated score, accumulated by e.g. getting Prizes.

Default: 0

=cut
use Class::MethodMaker get_set => [ "score" ];





=head2 lengthIdeal

The ideal length for the Worm. It will prolong itself to
this size when moving. It will not shrink.

=cut
use Class::MethodMaker get_set => [ "lengthIdeal" ];





=head2 lengthActual

The actual length of the Worm.

Readonly.

=cut
sub lengthActual {
    my $self = shift;
    return( scalar( @{$self->raBodyLocation} ) );
}





=head1 METHODS

=head2 new([$left = 11], [$top = 12], [$direction = "left"], [$length = 3)

Create new Worm, facing in $direction ("left", "right",
"up", "down" (only left supported right now)), with a body a
total size of $length.

=cut
sub new {
    my $pkg = shift;
    my ($left, $top, $direction, $length) = @_;
    defined($left) or $left = 11;
    defined($top) or $top = 12;
    $direction ||= "left";
    defined($length) or $length = 3;
    
    ###demo
    my $self = $pkg->SUPER::new( Game::Location->new($left, $top) );
    $self->oEventMove( Game::Event::Timed->new() )->timeInterval(0.07);
    $self->oDirection(Game::Direction->new($direction));
    $self->score(0);
    $self->lengthIdeal($length);
    $self->isRealPlayer(1);
    
    #Build worm body
    my $char = "O";
    if ($direction eq "left") {
        $self->buildBodyRight($length, $self->oLocation, sub { my $ret = $char; $char = "o"; $ret; });
    } else {
        die;
    }
    
    return($self);
}





=head2 moveForward()

Move forward one step in the oDirection.

Return 1 on success, else 0.

=cut
sub moveForward {
    my $self = shift;
    
    #Precalculate move
    my $oLocationOld = $self->oLocation;
    my $oLocationNew = $self->oValidLocationAfterMove($self->oLocation, $self->oDirection) or return(0);
    
    ##Do move
    $self->oLocation($oLocationNew);
    
    #Remove at tail, if not too short
    my $oLocationRemoved = undef;
    if (! ( $self->lengthActual < $self->lengthIdeal )) {
        $oLocationRemoved = pop(@{$self->raBodyLocation});
    }
    
    #Add at head, always (that's the move forward)
    unshift( @{$self->raBodyLocation}, $oLocationNew );
    
    #Tell the Lawn
    if ($self->oLawn) {
        $self->oLawn->objectHasMoved($self) or return(0);
        $self->oLawn->placeObjectBodyPartAt($self, $oLocationNew, $self->raBodyChar->[0]);
        $self->oLawn->placeObjectBodyPartAt($self, $oLocationOld, $self->raBodyChar->[1]) if(scalar($self->raBodyChar) > 1);
        $oLocationRemoved and $self->oLawn->removeObjectBodyPartAt($self, $oLocationRemoved);
    }
    
    return(1);
}





=head2 oValidLocationAfterMove()

Check that a movement in the $oDirection from $oLocation is
a valid one.

Return new Game::Location (with the new location) object on
success, else undef if the move wasn't valid.

=cut
sub oValidLocationAfterMove {
    my $self = shift;
    
    my $oLocationNew = $self->oDirection->oMove($self->oLocation, 1);
    
    #Check if it's valid
    if (my $oLawn = $self->oLawn) {
        $oLawn->isLocationValidForMove($self, $oLocationNew) or return(undef);
    }

    return($oLocationNew);
}




=head1 OTHER METHODS

=over 4

=item turn($direction)

Turn in $direction.
    left
    right

Return new direction on success, else undef.

=cut
sub turn {
    my $self = shift;
    my ($direction) = @_;

    eval { $self->oDirection->turn($direction); };
    return(undef) if($@);

    return($self->oDirection->direction);
}





=item grow([$sizeIncrease = 1])

Grow with $sizeIncrease body parts over time, i.e. increase the
lengthIdeal.

Return the new lengthIdeal() on success, or undef on errors.

=cut
sub grow {
    my $self = shift;
    my ($sizeIncrease) = @_;
    $sizeIncrease ||= 1;

    return( $self->lengthIdeal( $self->lengthIdeal + $sizeIncrease ) );
}





=back

=head2 Other other methods

=over 4

=item crash()

Crash the Worm. This doesn't mean anything in particular.

Notify the Lawn.

Return 1 on success, else 0.

=cut
sub crash {
    my $self = shift;

    $self->oLawn and ($self->oLawn->wormHasCrashed($self) or return(0));

    return(1);
}





=item checkTick($timeWorld)

Check if a tick is due. If it is, move forward.

Return 1 if a tick was due, else 0. Die if the worm can't
move.

=cut
sub checkTick {
    my $self = shift;
    my ($timeWorld) = @_;

    if ($self->oEventMove()->checkTick($timeWorld)) {
        ###demo
        if (!$self->moveForward()) {            
            ExceptionCouldNotMoveForward->throw(
                oObject => $self,
                error => "Could not move forward",
            );            
        }
            
        return(1);
    }

    return(0);
}





=item awardScorePoints($points)

Add $points to the score().

Return 1 on success, else 0.

=cut
sub awardScorePoints {
    my $self = shift;
    my ($points) = @_;

    $self->score( $self->score + $points );

    return(1);
}




=pod

=back

=cut





1;





#EOF
