=head1 NAME

Game::Direction - Direction, with the ability to turn and
move in the direction.

=head1 SYNOPSIS

Nah...

=cut





package Game::Direction;





use strict;
use Data::Dumper;
use Carp qw( confess croak );

use Game::Location;





=head1 PROPERTIES

=head2 direction

The direction.

    left
    right
    up
    down

Die on invalid input.

=cut
my $rhDirectionIndex = {
    "left" => 0,
    "up" => 1,
    "right" => 2,
    "down" => 3,
    };
my $rhIndexDirection = { map { $rhDirectionIndex->{$_} => $_ } keys %$rhDirectionIndex };
sub direction { my $self = shift;
    my ($dir) = @_;

    if($dir) {
        if($dir =~ /^(left|right|up|down)$/i) {
            $self->{direction} = $rhDirectionIndex->{ lc($dir) };
            }
        else {
            confess("Invalid direction ($dir)")
            }
        }

    return( $rhIndexDirection->{ $self->{direction} } );
}






=head1 METHODS

=head2 new([$direction = "left"])

Create new Direction.

Die on invalid input

=cut
sub new { my $pkg = shift;
    my ($direction) = @_;
    defined($direction) or $direction = "left";

    my $self = {};
    bless $self, $pkg;
    $self->direction($direction);

    return($self);
}





=head2 oMove($oLocation)

Return new Game::Location object with the new location after
a move of one step from $oLocation in the current direction.

Return 1 on success, else 0.

=cut
my $rhMove = {
    "left" => { left => -1, top => 0 },
    "right" => { left => 1, top => 0 },
    "up" => { left => 0, top => -1 },
    "down" => { left => 0, top => 1 },
    };
sub oMove { my $self = shift;
    my ($oLocation) = @_;

    my $oLocationNew = Game::Location->new(
            $oLocation->left + $rhMove->{$self->direction}->{left},
            $oLocation->top + $rhMove->{$self->direction}->{top},
            );

    return($oLocationNew);
}





=head2 turn($direction)

Turn in the $direction

    left
    right

Set new direction().

Return new direction. Die on invalid input.

=cut
my $rhDir = {
    "left" => -1,
    "right" => 1,
    };
sub turn { my $self = shift;
    my ($direction) = @_;

    my $dirIndex = $rhDir->{lc($direction)} || confess("Invalid direction ($direction)\n");
    
    my $no = keys %$rhDirectionIndex;
    $self->{direction} = ($self->{direction} += $dirIndex) % $no;

    return( $self->direction );
}





=head2 turnDifference($oDirection)

Figure out the difference between the direction of $self and 
$oDirection, expressed as a turn ("left"/"right"). 

"How should $self turn in order to for $self to be the same 
as $oDirection?"

Only a single turning motion is allowed, not a 180o turn.

Return the turn ("left"/"right"), else "" if no turn is 
good.

=cut
#my $rhDirectionIndex = {
#    up => 0,
#    right => 1,
#    down => 2,
#    left => 3,
#    };
sub turnDifference { my $self = shift;
    my ($oDirection) = @_;
    
    my $diff = $rhDirectionIndex->{$oDirection->direction} - $rhDirectionIndex->{$self->direction};
    $diff or return("");
    my $absDiff = abs($diff);
    my $sign = $diff / $absDiff;

    if($absDiff == 3) {
        $absDiff = 1;
        $diff = $sign * -1;
        }
    return( ($diff < 0) ? "left" : "right" ) if($absDiff == 1);
    return("");
}





1;





#EOF
