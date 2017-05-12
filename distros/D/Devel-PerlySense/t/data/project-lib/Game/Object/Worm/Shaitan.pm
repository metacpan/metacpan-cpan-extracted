=head1 NAME

Game::Object::Worm::Shaitan - Worm

=head1 SYNOPSIS

Nah...

=cut





package Game::Object::Worm::Shaitan;

push(@ISA, ("Game::Lawn", "Game::Object::Worm"));  #Eh, get it?





use strict;
use Data::Dumper;
use Carp qw( confess );





=head1 PROPERTIES

=head2 isRealPlayer

Whether this is a real life player or not.

Default: 0

=cut





=head2 probabilityTurnTowardsPrize

The probability (0..1) that the Worm will turn towards a 
prize when it's on the same line.

Default: 0 (no turning)

=cut
use Class::MethodMaker get_set => [ "probabilityTurnTowardsPrize" ];





=head1 METHODS

=head2 new([$left = 11], [$top = 12], [$direction = "left"], [$length = 3)

Create new Shaitan Worm, facing in $direction ("left", "right",
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





1;





#EOF

