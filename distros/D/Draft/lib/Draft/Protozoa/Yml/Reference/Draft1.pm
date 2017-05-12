package Draft::Protozoa::Yml::Reference::Draft1;

use strict;
use warnings;

use Draft::Entity::Reference;
use Draft::Protozoa::Yml;

use vars qw /@ISA/;
@ISA = qw /Draft::Entity::Reference Draft::Protozoa::Yml/;

sub _parse
{
    my $self = shift;
    my $data = shift;

    # rules for mapping file data into memory structures

    $self->{0} = $data->{points}->[0];
    $self->{location} = $data->{location};
    $self->{ignore} = $data->{ignore} || [];
}

# FIXME doesn't have Create(), Transform(), Rotate()

1;

