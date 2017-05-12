# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Response;
use strict;
use warnings;
use base qw(HTTP::Response);
use Storable qw(dclone);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{_notes} = {};
    return $self;
}

sub clone
{
    my $self  = shift;
    my $clone = $self->SUPER::clone;
    my $cloned_notes = dclone $self->notes;
    foreach my $note (keys %$cloned_notes) {
        $clone->notes( $note => $cloned_notes->{$note} );
    }
    return $clone;
}

sub notes
{
    my $self = shift;
    my $key  = shift;

    return $self->{_notes} unless $key;

    my $value = $self->{_notes}{$key};
    if (@_) {
        $self->{_notes}{$key} = $_[0];
    }
    return $value;
}

1;

__END__

=head1 NAME

Gungho::Response - Gungho HTTP Response Object

=head1 DESCRIPTION

This module is exactly the same as HTTP::Response, but adds notes()

=head1 METHODS

=head2 new

=head2 clone

=head2 notes

=cut
