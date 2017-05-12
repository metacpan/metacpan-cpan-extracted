package Draft::Entity::Reference;

=head1 NAME

Draft::Entity::Reference - CAD reference drawing-object

=head1 SYNOPSIS

Points to one or more L<Draft::Drawing> objects and places them in
space.

=cut

use strict;
use warnings;
use Draft::Drawing;

# FIXME shouldn't depend on Tk
use Draft::TkGui::Entity::Reference;
use vars qw /@ISA/;
@ISA = qw /Draft::TkGui::Entity::Reference/;

=pod

=head1 DESCRIPTION

A reference has some interesting attributes; coordinates for placing
it in space, paths to L<Draft::Drawing> objects and parts of them to
ignore.

=head1 USAGE

Processing the data in a Reference object causes referenced drawings
to be read if necessary:

    $self->Process;

=cut

sub Process
{
    my $self = shift;

    my $dir = $self->{_path};
    $dir =~ s/[^\/]*$//;

    for my $path (@{$self->{location}})
    {
        $path = _clean_path ($dir . $path);
        $Draft::WORLD->{$path} = Draft::Drawing->new ($path)
            unless exists $Draft::WORLD->{$path};
        $Draft::WORLD->{$path}->Read;
    }

    @{$self->{ignore}} = map _clean_path ($dir . $_), @{$self->{ignore}};
}

sub _clean_path
{
    my $path = shift;
    while ($path =~ /[^\/]\/\.\.\//) { $path =~ s/[^\/]+\/\.\.\/// }
    return $path;
}

1;
