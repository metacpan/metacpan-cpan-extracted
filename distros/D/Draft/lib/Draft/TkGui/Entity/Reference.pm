package Draft::TkGui::Entity::Reference;

=head1 NAME

Draft::TkGui::Entity::Reference - reference

=head1 SYNOPSIS

Points to one or more L<Draft::Drawing> objects and places them in
space.

=cut

use strict;
use warnings;

# FIXME should subclass Draft::Entity::Reference, not the other way around

#use Draft::Entity::Reference;
#use vars qw(@ISA);
#@ISA = qw(Draft::Entity::Reference);

=pod

=head1 DESCRIPTION

A reference has some interesting attributes; coordinates for placing
it in space, paths to L<Draft::Drawing> objects and parts of them to
ignore.

=cut

sub Draw
{
    my $self = shift;
    my ($canvas, $offset, $parents, $ignore) = @_;

    my $new_offset  = [map ($offset->[$_] + $self->{0}->[$_], 0 .. 2)];
    my $new_parents = [@$parents, $self->{_path}];
    my $new_ignore  = [@$ignore, @{$self->{ignore}}];

    for my $path (@{$self->{location}})
    {
        $Draft::WORLD->{$path}->Draw ($canvas, $new_offset, $new_parents, $new_ignore);
    }
}

1;
