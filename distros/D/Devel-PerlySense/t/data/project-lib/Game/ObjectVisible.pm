=head1 NAME

Game::ObjectVisible - General Object that can be on a Lawn.

=head1 SYNOPSIS

Nah...

=cut





package Game::ObjectVisible;





use strict;
use Data::Dumper;
use Game::Location;
use Game::Event::Timed;





=head1 PROPERTIES

=head2 oLocation

Game::Location object.

Default: (11, 12)

=cut

use Class::MethodMaker get_set => [ "oLocation" ];





=head2 oLawn

Game::Lawn object, if the Prize is placed on one.

Default: undef

=cut

use Class::MethodMaker get_set => [ "oLawn" ];





=head2 raBodyLocation

Array ref with hash refs (keys: top, left) that is the body
locations relative to the head.

Default: []

=cut

use Class::MethodMaker get_set => [ "raBodyLocation" ];





=head2 raBodyChar

Array ref with chars to use for displaying the body.

Default: []

=cut

use Class::MethodMaker get_set => [ "raBodyChar" ];





=head2 isBlocking

Whether the object blocks other objects, i.e. whether they 
can crash on this object.

Default: 1

=cut

use Class::MethodMaker get_set => [ "isBlocking" ];





=head2 color

What color this object has. This may influence the rendering of it on screen.

Default: "gray"

=cut

use Class::MethodMaker get_set => [ "color" ];





=head1 METHODS

=head2 new($oLocation)

Create new Object, located at Location.

=cut
sub new { my $pkg = shift;
    my ($oLocation) = @_;

    my $self = {};
    bless $self, $pkg;
    $self->color("gray");
    $self->oLawn(undef);
    $self->raBodyLocation([]);
    $self->raBodyChar([]);
    $self->oLocation( $oLocation->oClone() );
    $self->isBlocking(1);

    return($self);
}





=head2 _buildBodyRight($length, $oLocation, $rcChar)

Build the Object body (raBodyLocation and raBodychar), 
starting at $oLocation, going $length steps to the right. 
Each body char is the return value from calling $rcChar->().

Return 1 on success, else 0.

=cut
sub _buildBodyRight {
    my $self = shift;
    my ($length, $oLocation, $rcChar) = @_;
    
    for my $i (0..$length - 1) {
        push( @{$self->raBodyLocation}, Game::Location->new($oLocation->left + $i, $oLocation->top) );
        push( @{$self->raBodyChar}, $rcChar->() );
        }

    my $text = Game::Object::Worm->loadFile("jahadja");                
    
    return(1);
}





1;





#EOF
