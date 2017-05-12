=head1 NAME

Game::Application - Worm Game Application.

=head1 SYNOPSIS

Nah...

=cut





package Game::Application;





use strict;
use Data::Dumper;
use Game::Controller;
use Game::UI;

use Game::Controller;
use Game::Object::Worm;
use Game::Object::Worm::Bot;
use Game::Object::Prize;
use Game::Object::Wall;






=head1 PROPERTIES

=head2 oUI

Game::UI object.

=cut

use Class::MethodMaker get_set => [ "oUI" ];





=head1 METHODS

=head2 new()

Create new Application.

=cut
sub new { my $pkg = shift;

    my $self = {};
    bless $self, $pkg;

    $self->oUI( Game::UI->new($self) );

    return($self);
}





=head2 runMain()

Run the Main menu, providing the user with e.g. options to 
play.

Return 1 on success, else 0.

=cut
sub runMain { my $self = shift;

    $self->oUI->runMainMenu($self);

    return( 1 );
}





=head2 runGame()

Run the the Game, i.e. dispay a Lawn and start off the game.

Return 1 on success, else 0.

=cut
sub runGame {
    my $self = shift;
    
    my ($width, $height) = (74, 40);
    my ($offsetLeft, $offsetTop) = (3, 1);
    
    
    my $oController = Game::Controller->new($offsetLeft, $offsetTop, $width, $height);
    $oController->oUI->soundsEnabled(1);
    
    
    #Create worm
    my ($wormLeft, $wormTop, $wormDirection, $wormLength) = (40, 10, "left", 15);
    my $oWorm = Game::Object::Worm->new($wormLeft, $wormTop, $wormDirection, $wormLength);
    $oController->placeWormOnLawn($oWorm);
    
    
    my $oWormBot = Game::Object::Worm::Bot->new($wormLeft, $wormTop + 8, $wormDirection, $wormLength);
    $oWormBot->oEventMove->timeInterval(0.12);
    $oWormBot->probabilityTurnRandomly(0.04);
    $oWormBot->probabilityTurnTowardsPrize(1.00);
    $oController->placeWormBotOnLawn($oWormBot);
    
    
    $oWormBot = Game::Object::Worm::Bot->new($wormLeft, $wormTop + 16, $wormDirection, $wormLength);
    $oWormBot->probabilityTurnRandomly(0.07);
    $oWormBot->probabilityTurnTowardsPrize(0.60);
    $oController->placeWormBotOnLawn($oWormBot);
    
    
    $oWormBot = Game::Object::Worm::Bot->new($wormLeft, $wormTop + 24, $wormDirection, $wormLength);
    $oWormBot->probabilityTurnTowardsPrize(0.80);
    $oController->placeWormBotOnLawn($oWormBot);
    
    if(0) {
        for my $i (1..3) {
            $oWormBot = Game::Object::Worm::Bot->new($wormLeft - $i, $wormTop - 5 + ($i * 3), $wormDirection, $wormLength);
            $oWormBot->probabilityTurnRandomly(0.07);
            $oWormBot->probabilityTurnTowardsPrize(0.80);
            $oWormBot->oEventMove->timeInterval(0.12);
            $oController->placeWormBotOnLawn($oWormBot);
            }
        }
    
    
    my ($prizeLeft, $prizeTop, $value) = (11, 13, 100);
    my $oPrize = Game::Object::Prize->new(Game::Location->new($prizeLeft, $prizeTop), $value);
    $oController->placePrizeOnLawn($oPrize);
    
    $oPrize = Game::Object::Prize->new(Game::Location->new($prizeLeft + 40, $prizeTop + 2), $value);
    $oController->placePrizeOnLawn($oPrize);
    
    
    
    my ($wallLeft, $wallTop) = (30, 5);
    my $oWall = Game::Object::Wall->new(Game::Location->new($wallLeft, $wallTop), "horizontal", 30);
    $oController->placeWallOnLawn($oWall);
    
    $oWall = Game::Object::Wall->new(Game::Location->new(12, 16), "horizontal", 30);
    $oController->placeWallOnLawn($oWall);
    
    $oWall = Game::Object::Wall->new(Game::Location->new($wallLeft, $wallTop + 25), "horizontal", 30);
    $oController->placeWallOnLawn($oWall);
    
    
    my $dummy = Game::Object::Worm->loadFile("dummy.txt");
    
    eval { $oController->run(); };
    
    my $blah = Game::Object::Worm::Bot->loadFile("losfilos.txtos");
    sleep(2);


    return( 1 );
}





1;





__END__
