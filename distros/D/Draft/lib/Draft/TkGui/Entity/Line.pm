package Draft::TkGui::Entity::Line;

=head1 NAME

Draft::TkGui::Entity::Line - a line

=head1 SYNOPSIS

A line consists of two points.

=cut

use strict;
use warnings;

# FIXME should subclass Draft::Entity::Line, not the other way around

#use Draft::Entity::Line;
#use vars qw(@ISA);
#@ISA = qw(Draft::Entity::Line);

=pod

=head1 DESCRIPTION

Though a line consists of just two points, it should really be
extended to an arbitrary number of points - A polyline.

=cut

sub Draw
{
    my $self = shift;
    my ($canvas, $offset, $parents, $ignore) = @_;

    my $new_parents = [@$parents, $self->{_path}];

    my $tags = join (" ", @{$new_parents});

    for my $stuff (@{$new_parents})
    {
        if (defined $File::Atomism::EVENT->{_new}->{$stuff})
        {
            $canvas->createLine ($self->{0}->[0] + $offset->[0] ."m",
                                 $self->{0}->[1] + $offset->[1] ."m",
                                 $self->{1}->[0] + $offset->[0] ."m",
                                 $self->{1}->[1] + $offset->[1] ."m",
                                        -tags => $tags);
        }
    }
}

1;
