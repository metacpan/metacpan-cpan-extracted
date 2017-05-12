=head1 NAME

Game::Lawn - Lawn

=head1 SYNOPSIS

Nah...

=cut





package Game::Lawn;
#MI with common base class from Game::Object::Worm
use base qw( Game::Object );



use strict;
use Data::Dumper;

use Game::Object::Worm;
use Game::Object::Prize; 
use Game::UI::None; 
use Game::Location;




=head1 PROPERTIES

=head2 width

width

Default: 0

=cut

use Class::MethodMaker get_set => [ "width" ];





=head2 height

height coordinate

Default: 0

=cut

use Class::MethodMaker get_set => [ "height" ];





=head2 rhGrid

Hash ref with left->top->object hash ref tree.

Default: {}

=cut

use Class::MethodMaker get_set => [ "rhGrid" ];





=head2 oUI

Game::UI object, used to display the Lawn and stuff on it.

Default: undef

=cut

use Class::MethodMaker get_set => [ "oUI" ];





=head2 oController

Game::Controller object used to steer the game, or undef if there is no app.

Default: undef

=cut

use Class::MethodMaker get_set => [ "oController" ];





=head2 rhPrize

Hash ref with (key: object string, value:
Game::Object::Prize object). These are the Prizes the Lawn
knows about.

Default: {}

=cut

use Class::MethodMaker get_set => [ "rhPrize" ];





=head1 METHODS

=head2 new([$width = 0, $height = 0])

Create new Lawn

=cut
sub new { my $pkg = shift;
    my ($width, $height) = @_;
    $width ||= 0;
    $height ||= 0;

    my $self = {};
    bless $self, $pkg;

    $self->rhPrize({});
    $self->rhGrid({});
    $self->width($width);
    $self->height($height);
    $self->oUI(Game::UI::None->new());

    return($self);
}





=head2 oPlaceWorm($left, $top)

Place a new Worm on the Lawn, at the location $left/$top.

Return the new Game::Object::Worm object on success, else undef.

=cut
sub oPlaceWorm { my $self = shift;
    my ($left, $top) = @_;

    $self->placeObjectAt(my $oWorm = Game::Object::Worm->new($left, $top)) or return(undef);

    return($oWorm);
}





=head2 oPlacePrize($oLocation, $value)

Place a new Prize on the Lawn, at the location $left/$top.

Return the new Game::Object::Prize object on success, else undef.

=cut
sub oPlacePrize { my $self = shift;
    my ($oLocation, $value) = @_;

    $self->placeObjectAt(my $oPrize = Game::Object::Prize->new($oLocation, $value)) or return(undef);

    return($oPrize);
}





=head2 prizeWasClaimedBy($oPrize, $oObject)

The $oPrize was claimed by $oObject. Remove the $oPrize.
Notify the App and the UI.

Return 1 on success, else 0.

=cut
sub prizeWasClaimedBy { my $self = shift;
    my ($oPrize, $oObject) = @_;

    $self->removeObject($oPrize);

    $self->oController and ($self->oController->prizeWasClaimedBy($oPrize, $oObject) or return(0));
    $self->oUI and ($self->oUI->prizeWasClaimedBy($oPrize, $oObject) or return(0));

    return(1);
}





=head2 placeObjectAt($oObject)

Place a $oObject on the Lawn, at the object's oLocation().

Return 1 on success, else undef.

=cut
sub placeObjectAt { my $self = shift;
    my ($oObject) = @_;

    $oObject->oLawn($self);

    $self->isObjectLocationValidForPlacement($oObject) or return(0);

    #Collision detection? In the place method?
    $oObject->oLawn($self);   #Second call just to test two calls
    for my $oLocation (@{$oObject->raBodyLocation}) {
        $self->rhGrid->{$oLocation->left}->{$oLocation->top}->{$oObject} = $oObject;
        }

    #If it's prize, keep track of it separately
    $self->rhPrize->{$oObject} = $oObject if($oObject->isa("Game::Object::Prize"));

    $self->oUI->displayObjectAt($oObject);

    return(1);
}





=head2 objectHasMoved($oObject)

Notify the Lawn that $oObject has moved to a new location on
the Lawn, indicated by it's oLocation().

Check collisions and report to colliding objects.

Return 1 on success, else undef.

=cut
sub objectHasMoved { my $self = shift;
    my ($oObject) = @_;

    my ($left, $top) = ($oObject->oLocation->left, $oObject->oLocation->top);

    if(exists $self->rhGrid->{$left}->{$top}) {
        for my $oLawnObject (values %{$self->rhGrid->{$left}->{$top}} ) {
            if($oLawnObject ne $oObject) {
                if($oLawnObject->can("wasCrashedIntoBy")) {
                    $oLawnObject->wasCrashedIntoBy($oObject);
                    }
                }
            }
        }

    return(1);
}





=head2 removeObject($oObject)

Remove the object from the Lawn.

Return 1 on success, else 0.

=cut
sub removeObject { my $self = shift;
    my ($oObject) = @_;

    for my $oLocation (@{$oObject->raBodyLocation}) {
        $self->removeObjectBodyPartAt($oObject, $oLocation);
        }

    $oObject->oLawn(undef);

    #If it's prize, keep track of it separately
    delete $self->rhPrize->{$oObject} if($oObject->isa("Game::Object::Prize"));
    
    return(1);
}





=head2 isObjectAt($oObject, $left, $top)

Is the $oObject on the Lawn, at the location $left/$top?

Return 1 if it is, else 0.

=cut
sub isObjectAt { my $self = shift;
    my ($oObject, $left, $top) = @_;
    $self->isLocationOnLawn(Game::Location->new($left, $top)) or return(0);

    return(1) if(exists $self->rhGrid->{$left}->{$top}->{$oObject});

    return(0);
}





=head2 isAnythingAt($oLocation)

Is there an object on the Lawn, at the Location?

Return 1 if it is, else 0.

=cut
sub isAnythingAt { my $self = shift;
    my ($oLocation) = @_;

    if(exists $self->rhGrid->{$oLocation->left}->{$oLocation->top}) {
        return(1) if( values %{$self->rhGrid->{$oLocation->left}->{$oLocation->top}} );
        }

    return(0);
}





=head2 isAnythingBlockingAt($oLocation)

Is there a blocking object on the Lawn, at the Location?

Return 1 if it is, else 0.

=cut
sub isAnythingBlockingAt { my $self = shift;
    my ($oLocation) = @_;

    if(exists $self->rhGrid->{$oLocation->left}->{$oLocation->top}) {
        for my $oLawnObject (values %{$self->rhGrid->{$oLocation->left}->{$oLocation->top}} ) {
            return(1) if($oLawnObject->isBlocking);
            }
        }

    return(0);
}





=head2 oLocationRandom()

Return Game::Location object with a random Location on the
Lawn.

=cut
sub oLocationRandom { my $self = shift;

    my $left = int(rand( $self->width ));
    my $top = int(rand( $self->height ));

    return( Game::Location->new($left, $top) );
}





=head2 isLocationOnLawn($oLocation)

Is the Location on the Lawn?

Return 1 if it is, else 0.

=cut
sub isLocationOnLawn { my $self = shift;
    my ($oLocation) = @_;
    ($oLocation->left < $self->width) && ($oLocation->top < $self->height) &&
            ($oLocation->left >= 0) && ($oLocation->top >= 0)
                    or return(0);

    return(1);
}





=head2 isLocationValidForMove($oObject, $oLocation)

Is the $oLocation a valid location for $oObject to move to?

Ignore the movement/speed/whatever of $oObject, the only
concern is the validity of the Location in itself (whether
it's occupied by something important).

Return 1 if it is, else 0.

=cut
sub isLocationValidForMove { my $self = shift;
    my ($oObject, $oLocation) = @_;

    return(0) if(!$self->isLocationOnLawn($oLocation));
    return(0) if($self->isAnythingBlockingAt($oLocation));

    return(1);
}





=head2 isLocationValidForPlacement($oLocation)

Is the $oLocation a valid location for $oObject to be place at?

Ignore the movement/speed/whatever of $oObject, the only
concern is the validity of the Location in itself (whether
it's occupied by something).

Return 1 if it is, else 0.

=cut
sub isLocationValidForPlacement { my $self = shift;
    my ($oLocation) = @_;

    return(0) if(!$self->isLocationOnLawn($oLocation));
    return(0) if($self->isAnythingAt($oLocation));

    return(1);
}





=head2 isObjectLocationValidForPlacement($oObject)

Is the raBodyLocation of the $oObject valid for placement on 
the Lawn. The entire raBodyLocation of $oObject must be 
valid.

Return 1 if it is, else 0.

=cut
sub isObjectLocationValidForPlacement { my $self = shift;
    my ($oObject) = @_;

    for my $oLocation (@{$oObject->raBodyLocation}) {
        $self->isLocationValidForPlacement($oLocation) or return(0);
        }    

    return(1);
}





=head2 oDirectionToPrize($oLocation)

Is there any Prize located in a straight line from
$oLocation? If so, return a Game::Direction object with the
direction to the prize.

If there are many applicable Prizes, pick any.

Return the Game::Direction object on success, else undef.

=cut
sub oDirectionToPrize { my $self = shift;
    my ($oLocation) = @_;

    my $dir = "";
    my ($left, $top) = ($oLocation->left, $oLocation->top);
    for my $oPrize (values %{$self->rhPrize}) {
        if($left == $oPrize->oLocation->left) {
            $dir = "up" if($oPrize->oLocation->top < $top);
            $dir = "down" if($oPrize->oLocation->top > $top);
            }
        elsif($top == $oPrize->oLocation->top) {
            $dir = "left" if($oPrize->oLocation->left < $left);
            $dir = "right" if($oPrize->oLocation->left > $left);
            }
        }
    $dir and return(Game::Direction->new($dir));

    return(undef);
}





=head2 placeObjectBodyPartAt($oObject, $oLocation, $char)

Put the $char of $oObject at $oLocation on the Lawn.

Return 1 on success, else 0.

=cut
sub placeObjectBodyPartAt { my $self = shift;
    my ($oObject, $oLocation, $char) = @_;

    $self->rhGrid->{$oLocation->left}->{$oLocation->top}->{$oObject} = $oObject;
    $self->oUI->displayObjectBodyPartAt($oLocation, $char, $oObject);

    return(1);
}





=head2 removeObjectBodyPartAt($oObject, $oLocation)

Remove the $oObject at $oLocation on the Lawn.

Return 1 on success, else 0.

=cut
sub removeObjectBodyPartAt { my $self = shift;
    my ($oObject, $oLocation) = @_;

    delete $self->rhGrid->{$oLocation->left}->{$oLocation->top}->{$oObject};
    $self->oUI->displayObjectBodyPartAt($oLocation);

    return(1);
}





=head2 wormHasCrashed($oObject)

The worm $oObject has crashed.

Notify the UI.

Return 1 on success, else 0.

=cut
sub wormHasCrashed { my $self = shift;
    my ($oObject) = @_;

    $self->oUI and ($self->oUI->wormHasCrashed($oObject) or return(0));
    $self->oController and ($self->oController->wormHasCrashed($oObject) or return(0));

    return(1);
}





END {
    my ($oObject) = @_;

    $oObject->oLawn(undef);
}




1;





#EOF
