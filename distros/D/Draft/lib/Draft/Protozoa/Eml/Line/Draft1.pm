package Draft::Protozoa::Eml::Line::Draft1;

=head1 NAME

Draft::Protozoa::Eml::Line::Draft1 - CAD line drawing-object

=head1 SYNOPSIS

A line consists of two points.

=cut

use strict;
use warnings;
use Draft::Protozoa::Eml;
use Draft::Entity::Line;

use vars qw /@ISA/;
@ISA = qw /Draft::Protozoa::Eml Draft::Entity::Line/;

=pod

=head1 DESCRIPTION

Though a line consists of just two points, it should really be
extended to an arbitrary number of points - A polyline.

=cut

sub _parse
{
    my $self = shift;
    my $data = shift;

    $self->{0} = $data->{0};
    $self->{1} = $data->{1};
}

1;
