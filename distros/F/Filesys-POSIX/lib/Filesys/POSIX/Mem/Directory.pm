# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Mem::Directory;

use strict;
use warnings;

use Filesys::POSIX::Directory ();

our @ISA = qw(Filesys::POSIX::Directory);

sub new {
    my ( $class, %initial ) = @_;
    return bless \%initial, $class;
}

sub get {
    my ( $self, $name ) = @_;
    return $self->{$name};
}

sub set {
    my ( $self, $name, $inode ) = @_;
    $self->{$name} = $inode;
    return $inode;
}

sub exists {
    my ( $self, $name ) = @_;
    return exists $self->{$name};
}

sub detach {
    my ( $self, $name ) = @_;
    my $inode = $self->{$name};

    delete $self->{$name};

    return $inode;
}

sub delete {
    my ( $self, $name ) = @_;

    return $self->detach($name);
}

sub list {
    my ($self) = @_;
    return keys %$self;
}

sub count {
    my ($self) = @_;
    return scalar keys %$self;
}

sub open {
    my ($self) = @_;

    $self->rewind;

    return $self;
}

sub rewind {
    my ($self) = @_;

    keys %$self;
}

sub read {
    my ($self) = @_;

    each %$self;
}

sub close {
    return;
}

1;
