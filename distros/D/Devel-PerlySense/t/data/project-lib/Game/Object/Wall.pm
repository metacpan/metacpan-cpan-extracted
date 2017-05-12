=head1 NAME

Game::Object::Wall - Wall

=head1 SYNOPSIS

Nah...

=cut





package Game::Object::Wall;
use base qw( Game::Object );





use strict;
use Data::Dumper;
use Game::Location;
use Game::Direction;





=head1 PROPERTIES

=head1 METHODS

=head2 new($oLocation, [$alignment = "horizontal"], [$length = 3)

Create new Wall with $alignment ("horizontal"), with a total 
size of $length.

=cut
sub new { my $pkg = shift;
    my ($oLocation, $alignment, $length) = @_;
    $alignment ||= "horizontal";
    defined($length) or $length = 3;

    my $self = $pkg->SUPER::new( $oLocation );

    #Build Wall body
    my $char = "X";
    if($alignment eq "horizontal") {
        $self->buildBodyRight($length, $oLocation, sub { "x" });
#        for my $i (0..$length - 1) {
#            push( @{$self->raBodyLocation}, Game::Location->new($oLocation->left + $i, $oLocation->top) );
#            push( @{$self->raBodyChar}, $char );
#            }
        }
    else {
        die;
        }

    return($self);
}





1;





#EOF
