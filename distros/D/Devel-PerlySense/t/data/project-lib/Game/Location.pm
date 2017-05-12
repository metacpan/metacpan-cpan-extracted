=head1 NAME

Game::Location - Location on a Lawn

=head1 SYNOPSIS

Nah...

=cut





package Game::Location;





use strict;
use Data::Dumper;





=head1 PROPERTIES

=head2 left

Left coordinate

Default: 0

=cut

use Class::MethodMaker get_set => [ "left" ];





=head2 top

Top coordinate

Default: 0

=cut

use Class::MethodMaker get_set => [ "top" ];





=head1 METHODS

=head2 new([$left = 0, $top = 0])

Create new Location

=cut
sub new { my $pkg = shift;
    my ($left, $top) = @_;
    $left ||= 0;
    $top ||= 0;

    my $self = {};
    bless $self, $pkg;
    
    $self->left($left);
    $self->top($top);

    return($self);
}





=head2 oClone()

Returned cloned object of $self.

=cut
sub oClone { my $self = shift; my $pkg = ref($self);
    return( $pkg->new($self->left, $self->top) );
}





1;





#EOF
