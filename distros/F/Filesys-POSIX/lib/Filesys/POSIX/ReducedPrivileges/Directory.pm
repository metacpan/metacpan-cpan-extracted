package Filesys::POSIX::ReducedPrivileges::Directory;

# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Real::Directory ();
use Carp                            ();
use Try::Tiny;

our @ISA = qw(Filesys::POSIX::Real::Directory);
our $AUTOLOAD;

sub new {
    my ( $class, $path, $inode ) = @_;
    unless ( defined $inode->{dev} && ref $inode->{dev} && $inode->{dev}->isa('Filesys::POSIX::ReducedPrivileges') ) {
        Carp::confess("invalid filesystem device");
    }

    return $class->SUPER::new( $path, $inode );
}

sub _sync_member {
    my ( $self, $name ) = @_;
    $self->{inode}{dev}->enter_filesystem();
    try {
        my $subpath = "$self->{'path'}/$name";
        my @st      = lstat $subpath;

        if ( scalar @st == 0 && $!{'ENOENT'} ) {
            delete $self->{'members'}->{$name};
        }
        else {

            Carp::confess($!) unless @st;

            if ( exists $self->{'members'}->{$name} ) {
                $self->{'members'}->{$name}->update(@st);
            }
            else {
                $self->{'members'}->{$name} = Filesys::POSIX::ReducedPrivileges::Inode->from_disk(
                    $subpath,
                    'st_info' => \@st,
                    'dev'     => $self->{'inode'}->{'dev'},
                    'parent'  => $self->{'inode'}
                );
            }
        }
    }
    catch {
        $self->{inode}{dev}->exit_filesystem();
        die $_;
    };
    $self->{inode}{dev}->exit_filesystem();
    return;
}

# Wrap all of the normal Inode methods with privilege dropping and restoring.
BEGIN {
    foreach my $method (qw(_sync_all rename_member delete open rewind read close)) {
        my $super_method = "SUPER::$method";
        no strict 'refs';
        *{ __PACKAGE__ . "::$method" } = sub {
            my ( $self, @args ) = @_;
            $self->{inode}{dev}->enter_filesystem();
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
                $self->{inode}{dev}->exit_filesystem();
                die $_;
            };
            $self->{inode}{dev}->exit_filesystem();
            return $context ? @result : defined $context ? $result[0] : ();
        };
    }
}

1;
