package Draft::Protozoa::Eml::Reference::Draft1;

=head1 NAME

Draft::Protozoa::Eml::Reference::Draft1 - CAD reference drawing-object

=head1 SYNOPSIS

Points to one or more L<Draft::Drawing> objects and places them in
space.

=cut

use strict;
use warnings;
use Draft::Drawing;
use Draft::Protozoa::Eml;
use Draft::Entity::Reference;

use vars qw /@ISA/;
@ISA = qw /Draft::Protozoa::Eml Draft::Entity::Reference/;

=pod

=head1 DESCRIPTION

A reference has some interesting attributes; coordinates for placing
it in space, paths to L<Draft::Drawing> objects and parts of them to
ignore.

=cut

sub _parse
{
    my $self = shift;
    my $data = shift;

    $self->{0} = $data->{0};
    $self->{location} = $data->{location};
    $self->{ignore} = $data->{ignore};
}

1;
