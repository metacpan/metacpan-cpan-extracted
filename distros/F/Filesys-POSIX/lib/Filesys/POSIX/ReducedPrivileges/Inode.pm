package Filesys::POSIX::ReducedPrivileges::Inode;

# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::ReducedPrivileges::Directory ();
use Filesys::POSIX::Real::Inode                  ();
use Filesys::POSIX::Mem::Inode                   ();
use Filesys::POSIX::Bits;
use Filesys::POSIX::Bits::System;
use Filesys::POSIX::Error qw(throw);
use Carp ();

use Fcntl qw(:DEFAULT :mode);
use Try::Tiny;

our @ISA = qw(Filesys::POSIX::Real::Inode);
our $AUTOLOAD;

sub new {
    my ( $class, $path, %opts ) = @_;
    unless ( defined $opts{dev} && ref $opts{dev} && $opts{dev}->isa('Filesys::POSIX::ReducedPrivileges') ) {
        Carp::confess("invalid filesystem device");
    }

    # No need to enter the ReducedContext for new. No file operations are performed.
    # Typically new() is called by from_disk() anyway
    return $class->SUPER::new( $path, %opts );
}

sub from_disk {
    my ( $class, $path, %opts ) = @_;
    unless ( defined $opts{dev} && ref $opts{dev} && $opts{dev}->isa('Filesys::POSIX::ReducedPrivileges') ) {
        Carp::confess("invalid filesystem device");
    }

    my $self;
    $opts{dev}->enter_filesystem();
    try {
        $self = $class->SUPER::from_disk( $path, %opts );
    }
    catch {
        $opts{dev}->exit_filesystem();
        die $_;
    };

    $opts{dev}->exit_filesystem();

    # Fix the class of the directory object
    bless $self->{directory}, 'Filesys::POSIX::ReducedPrivileges::Directory' if ( ref $self->{directory} );

    return $self;
}

# Wrap the normal Inode methods that do actual filesystem activity with privilege dropping and restoring.
BEGIN {
    foreach my $method (qw(open chown chmod readlink symlink child)) {
        my $super_method = "SUPER::$method";
        no strict 'refs';
        *{ __PACKAGE__ . "::$method" } = sub {
            my ( $self, @args ) = @_;
            $self->{dev}->enter_filesystem();
            my $context = wantarray();
            my @result;
            try {
                if ($context) {
                    @result = $self->$super_method(@args);
                }
                elsif ( defined $context ) {
                    @result = ( scalar $self->$super_method(@args) );
                }
                else {
                    $self->$super_method(@args);
                }
            }
            catch {
                $self->{dev}->exit_filesystem();
                die $_;
            };
            $self->{dev}->exit_filesystem();
            return $context ? @result : defined $context ? $result[0] : ();
        };
    }
}

1;
