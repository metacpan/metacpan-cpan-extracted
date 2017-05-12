package Draft::Protozoa::Yml::Line::Draft1;

use strict;
use warnings;

use Draft::Entity::Line;
use Draft::Protozoa::Yml;

use vars qw /@ISA/;
@ISA = qw /Draft::Entity::Line Draft::Protozoa::Yml/;

sub _parse
{
    my $self = shift;
    my $data = shift;

    # rules for mapping file data into memory structures

    $self->{0} = $data->{points}->[0];
    $self->{1} = $data->{points}->[1];
}

# FIXME doesn't have Create(), Transform(), Rotate()

1;

