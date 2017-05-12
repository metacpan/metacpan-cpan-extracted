package Draft::Entity::Line;

=head1 NAME

Draft::Entity::Line - CAD line drawing-object

=head1 SYNOPSIS

A line consists of two points.

=cut

use strict;
use warnings;

# FIXME shouldn't depend on Tk
use Draft::TkGui::Entity::Line;
use vars qw /@ISA/;
@ISA = qw /Draft::TkGui::Entity::Line/;

=pod

=head1 DESCRIPTION

Though a line consists of just two points, it should really be
extended to an arbitrary number of points - A polyline.

=cut

sub Process {}

1;
