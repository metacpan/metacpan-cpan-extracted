package Draft::TkGui::Drawing;

=head1 NAME

Draft::TkGui::Drawing - Tk drawing type

=head1 SYNOPSIS

A container for multiple drawing entities.

=head1 DESCRIPTION

Code for displaying a drawing on screen.

=cut

use strict;
use warnings;

# FIXME should subclass Draft::Drawing, not the other way around

#use vars qw(@ISA);
#@ISA = qw(Draft::Drawing);

sub Draw
{
    my $self = shift;
    my ($canvas, $offset, $parents, $ignore) = @_;

    $self->Read;

    foreach my $key (keys %{$self})
    {
        next if ($key =~ /^_/);
        next if grep (/^$key$/, @{$ignore});

        $self->{$key}->Draw ($canvas, $offset, $parents, $ignore);
    }
}

1;
