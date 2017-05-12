# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Mem::Inode;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Inode             ();
use Filesys::POSIX::Directory::Handle ();
use Filesys::POSIX::Mem::Bucket       ();
use Filesys::POSIX::Mem::Directory    ();

use Filesys::POSIX::Error qw(throw);

our @ISA = qw(Filesys::POSIX::Inode);

sub new {
    my ( $class, %opts ) = @_;
    my $now = time;

    my $inode = bless {
        'size'   => 0,
        'atime'  => $now,
        'mtime'  => $now,
        'ctime'  => $now,
        'uid'    => 0,
        'gid'    => 0,
        'mode'   => defined $opts{'mode'} ? $opts{'mode'} : 0,
        'dev'    => $opts{'dev'},
        'rdev'   => defined $opts{'rdev'} ? $opts{'rdev'} : 0,
        'parent' => $opts{'parent'}
    }, $class;

    if ( exists $opts{'mode'} && ( $opts{'mode'} & $S_IFMT ) == $S_IFDIR ) {
        $inode->{'directory'} = Filesys::POSIX::Mem::Directory->new(
            '.'  => $inode,
            '..' => $opts{'parent'} ? $opts{'parent'} : $inode
        );
    }

    return $inode;
}

sub child {
    my ( $self, $name, $mode ) = @_;
    my $directory = $self->directory;

    throw &Errno::EEXIST if $directory->exists($name);

    my $child = __PACKAGE__->new(
        'mode'   => $mode,
        'dev'    => $self->{'dev'},
        'parent' => $directory->get('.')
    );

    $directory->set( $name, $child );

    return $child;
}

sub chown {
    my ( $self, $uid, $gid ) = @_;
    @{$self}{qw(uid gid)} = ( $uid, $gid );
}

sub chmod {
    my ( $self, $mode ) = @_;
    my $format = $self->{'mode'} & $S_IFMT;
    my $perm = $mode & ( $S_IPERM | $S_IPROT );

    $self->{'mode'} = $format | $perm;
}

sub readlink {
    my ($self) = @_;

    throw &Errno::EINVAL unless $self->link;

    return $self->{'dest'};
}

sub symlink {
    my ( $self, $dest ) = @_;

    throw &Errno::EINVAL unless $self->link;

    $self->{'dest'} = $dest;

    return $self;
}

sub open {
    my ( $self, $flags ) = @_;

    if ( $self->dir ) {
        return Filesys::POSIX::Directory::Handle->new;
    }

    my $dev_flags = $self->{'dev'}->{'flags'};

    unless ( $self->{'bucket'} ) {
        $self->{'bucket'} = Filesys::POSIX::Mem::Bucket->new(
            'inode' => $self,
            'max'   => $dev_flags->{'bucket_max'},
            'dir'   => $dev_flags->{'bucket_dir'}
        );
    }

    return $self->{'bucket'}->open($flags);
}

1;
