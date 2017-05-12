=head1 NAME

Game::Object::Prize - Prize

=head1 SYNOPSIS

Nah...

=cut





package Game::Object::Prize;
use base qw( Game::Object );





use strict;
use Data::Dumper;
use Game::Location;
use Game::Event::Timed;





=head1 PROPERTIES

=head2 value

How much to win when getting the Prize.

Default: 0

=cut

use Class::MethodMaker get_set => [ "value" ];





=head2 isBlocking

Whether the object blocks other objects, i.e. whether they 
can crash on this object.

Default: 0

=cut





=head1 METHODS

=head2 new($oLocation, $value)

Create new Prize, located at Location, with a $value.

=cut
sub new { my $pkg = shift;
    my ($oLocation, $value) = @_;

    my $self = $pkg->SUPER::new($oLocation);
    $self->color("yellow");
    $self->value($value);
    $self->isBlocking(0);

    #Build Prize body
    $self->buildBodyRight(1, $oLocation, sub { '$' });

    return($self);
}





=head2 wasCrashedIntoBy($oObject)

This object was chrashed into by $oObject.

If possible, award the value() to $oObject.

If possible, notify the oLawn() that this Prize is claimed.

Return 1 on success, else 0.

=cut
sub wasCrashedIntoBy { my $self = shift;
    my ($oObject) = @_;

    $oObject->can("awardScorePoints") and $oObject->awardScorePoints( $self->value ) or return(0);

    $self->oLawn and ($self->oLawn->prizeWasClaimedBy($self, $oObject) or return(0));

    return(1);
    }





#sub DESTROY { print "PRIZE DESTROYED"; }





1;





#EOF
