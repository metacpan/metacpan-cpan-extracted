=head1 NAME

Game::Controller - Worm Game Controller with a Worm, Lawn, UI etc.

=head1 SYNOPSIS

Nah...

=cut





package Game::Controller;





use strict;
use Data::Dumper;
use Time::HiRes qw( time sleep );

use Game::Lawn;
use Game::Object::Worm;
use Game::Object::Worm::Bot;
use Game::UI;





=head1 PROPERTIES

=head2 oWorm

Game::Object::Worm object controlled by user.

Default: undef

=cut

use Class::MethodMaker get_set => [ "oWorm" ];





=head2 oLawn

Game::Lawn object.

=cut

use Class::MethodMaker get_set => [ "oLawn" ];





=head2 oUI

Game::UI object.

=cut

use Class::MethodMaker get_set => [ "oUI" ];





=head2 rhTimedObject

Hash ref with (key: object, value: object) with objects that 
should be timed in the main loop.

Default: {}

=cut

use Class::MethodMaker get_set => [ "rhTimedObject" ];





=head1 METHODS

=head2 new($offsetLeft, $offsetTop, $lawnWidth, $lawnHeight)

Create new App with a UI located at $offsetLeft/$offsetTop,
with a Lawn with the dimensions $lawnWidth, $lawnHeight.

=cut
sub new { my $pkg = shift;
    my ($offsetLeft, $offsetTop, $lawnWidth, $lawnHeight) = @_;

    my $self = {};
    bless $self, $pkg;

    $self->rhTimedObject({});
    $self->oLawn( Game::Lawn->new($lawnWidth, $lawnHeight) );

    $self->oUI( Game::UI->new() );
    $self->oUI->offsetLeft($offsetLeft);
    $self->oUI->offsetTop($offsetTop);
    $self->oUI->oLocationScore( Game::Location->new($offsetLeft, $offsetTop + $lawnHeight) );
    
    $self->oLawn->oUI($self->oUI);
    $self->oLawn->oController($self);


    $self->oUI->displayLawn($self->oLawn) or return(undef);

    return($self);
}





=head2 placeWormOnLawn($oObject)

Place the $oObject on the Lawn and keep track of it.

Return 1 on success, else 0.

=cut
sub placeWormOnLawn { my $self = shift;
    my ($oObject) = @_;
    $self->oWorm( $oObject );
    $self->addTimedObject($oObject);
    return( $self->placeObjectOnLawn($oObject) );
}





=head2 placeWormBotOnLawn($oObject)

Place the $oObject on the Lawn and keep track of it.

Return 1 on success, else 0.

=cut
sub placeWormBotOnLawn { my $self = shift;
    my ($oObject) = @_;

    $self->placeObjectOnLawn($oObject) or return(0);
    $self->addTimedObject($oObject) or return(0);
    
    return(1);
}





=head2 placePrizeOnLawn($oObject)

Place the $oObject on the Lawn and keep track of it.

Return 1 on success, else 0.

=cut
sub placePrizeOnLawn { my $self = shift;
    my ($oObject) = @_;
    return( $self->placeObjectOnLawn($oObject) );
}





=head2 placeWallOnLawn($oObject)

Place the $oObject on the Lawn and keep track of it.

Return 1 on success, else 0.

=cut
sub placeWallOnLawn { my $self = shift;
    my ($oObject) = @_;
    return( $self->placeObjectOnLawn($oObject) );
}





=head2 placeObjectOnLawn($oObject)

Place the $oObject on the Lawn and keep track of it.

Return 1 on success, else 0.

=cut
sub placeObjectOnLawn { my $self = shift;
    my ($oObject) = @_;

    $oObject->oLawn( $self->oLawn ) if($oObject->can("oLawn"));
    $self->oLawn->placeObjectAt($oObject) or return(0);

    return(1);
}





=head2 addTimedObject($oObject)

Add $oObject to the rhTimedObject, to be timed in the main 
loop.

Return 1 on success, else 0.

=cut
sub addTimedObject { my $self = shift;
    my ($oObject) = @_;

    $self->rhTimedObject->{$oObject} = $oObject;

    return(1);
}





=head2 removeWormFromLawn($oObject)

Remove the Worm $oObject from the Lawn and the App.

Return 1 on success, else 0.

=cut
sub removeWormFromLawn { my $self = shift;
    my ($oObject) = @_;

    delete $self->rhTimedObject->{$oObject};
    
    $self->oLawn->removeObject($oObject) or return(0);

    return(1);
}





=head2 createWormBotLike([$oObject])

Create a new Worm Bot. If $oObject is passed, clone values 
from it. 

Place the new Bot somewhere on the Lawn.

Return 1 on success, else 0.

=cut
sub createWormBotLike { my $self = shift;
    my ($oObject) = @_;
    
    my $length = 10;

    for (1..50) {        #Try at most n times
        my $oLocation = $self->oLawn->oLocationRandom();
        my $oWormBot = Game::Object::Worm::Bot->new($oLocation->left, $oLocation->top, "left", $length);
        if($oObject) {
            $oWormBot->cloneValuesFrom($oObject);    
            }
        else {
            $oWormBot->oEventMove->timeInterval(0.12);
            $oWormBot->probabilityTurnRandomly(0.04);
            $oWormBot->probabilityTurnTowardsPrize(1.00);
            }
        
        $self->placeWormBotOnLawn($oWormBot) and return(1);
        }

    warn("Failed to place new worm\n");
    
    return(0);
}





=head2 run()

Run the main loop.

Return 1 on success, else 0. Die on fatal errors.

=cut
sub run { my $self = shift;

    my %hAction;
    if($self->oWorm) {
        %hAction = (
            "turn left" => sub { $self->oWorm->turn("left"); },
            "turn right" => sub { $self->oWorm->turn("right"); },
            );
        }

    while(1) {
        my $timeWorld = time();

        for my $oObject (values %{$self->rhTimedObject}) {
            
            eval {
                if($oObject->checkTick($timeWorld)) {
                
                    if($oObject eq ($self->oWorm || "")) {
                        #The Worm moved, check for user input
            
                        my $action = $self->oUI->getUserAction();
                        return(1) if($action eq "quit");
                        
                        if(my $rcAction = $hAction{ $action }) {
                            $rcAction->();
                            }
                        }
                        
                    }
                };
            if($@) {
                if(UNIVERSAL::isa($@, "ExceptionCouldNotMoveForward")) {
                    my $oCrashedObject = $@->oObject or die;
                    
                     $oCrashedObject->crash() or die;
                    
                    die if($oCrashedObject->isRealPlayer);
                    }
                else {
                    die;
                    }
                }
            }

        sleep(0.005);
        }


    return(1);
}





=head2 prizeWasClaimedBy($oPrize, $oObject)

The $oPrize was just claimed by $oObject and removed from 
the Lawn.

Update the score display.

Put another Prize on the Lawn

Return 1 on success, else 0.

=cut
sub prizeWasClaimedBy { my $self = shift;
    my ($oPrize, $oObject) = @_;

    $self->oWorm and ($self->oUI->showScore( $self->oWorm->score ) or return(0));

    ##Todo: Configurable whether the Worm should grow
    $oObject->can("grow") and $oObject->grow();

    ##Todo: Configurable whether a new Prize should appear
    for(1..500) {    #Attempt to place a prize n times, then fail. It may fail because the random loc is on something
        $self->oLawn->oPlacePrize( 
                Game::Location->new( 
                        int(rand($self->oLawn->width - 1)), 
                        int(rand($self->oLawn->height - 1))
                ), 100 ) and return(1);
        }
    warn("Failed to place Prize");

    return(0);
}





=head2 wormHasCrashed($oObject)

The Worm $oObject just crashed.

If it was a bot, replace it.

#If it was a player, do something...

Return 1 on success, else 0.

=cut
sub wormHasCrashed { my $self = shift;
    my ($oObject) = @_;

    $oObject->isa("Game::Object::Worm::Bot") or return(1);
    
    $self->removeWormFromLawn($oObject) or return(0);
    $self->createWormBotLike($oObject) or return(0);

    return(1);
}





1;





#EOF
