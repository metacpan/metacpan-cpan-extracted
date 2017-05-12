# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Snapshot::Inode;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Mem::Inode     ();
use Filesys::POSIX::Mem::Directory ();
use Filesys::POSIX::Mem::Bucket    ();

use Filesys::POSIX::Error qw(throw);

our @ISA = qw(Filesys::POSIX::Mem::Inode);

sub from_inode {
    my ( $class, $inode, %opts ) = @_;

    my $new_inode = bless {
        'inode'  => $inode,
        'copied' => 0
    }, $class;

    my @ATTRIBUTES = qw(
      size atime mtime ctime uid gid mode dev rdev parent
    );

    @{$new_inode}{@ATTRIBUTES} = @{$inode}{@ATTRIBUTES};

    #
    # Overwrite any values within the current inode with ones optionally passed
    # in %opts.
    #
    foreach my $attribute (@ATTRIBUTES) {
        $new_inode->{$attribute} = $opts{$attribute}
          if exists $opts{$attribute};
    }

    #
    # Copy the symlink destination from the given inode provided, if
    # present.
    #
    if ( $inode->link ) {
        $new_inode->{'dest'} = $inode->readlink;
    }

    #
    # If it was specified at mount time that we should snapshot directory
    # listings immediately, then do so.
    #
    if ( $inode->dir && $opts{'dev'}->{'flags'}->{'immediate_dir_copy'} ) {
        $new_inode->{'directory'} = $new_inode->_copy_dir( $inode->directory );
    }

    return $new_inode;
}

sub _copy_dir {
    my ( $self, $directory ) = @_;

    my $new_directory = Filesys::POSIX::Mem::Directory->new;

    $directory->open;

    while ( defined( my $item = $directory->read ) ) {
        next if $item eq '.' || $item eq '..';

        my $inode = $directory->get($item);

        $new_directory->set(
            $item,
            __PACKAGE__->from_inode(
                $inode,
                'parent' => $self,
                'dev'    => $self->{'dev'}
            )
        );
    }

    $directory->close;

    return $new_directory;
}

sub _copy_file {
    my ($self) = @_;

    my $dev_flags  = $self->{'dev'}->{'flags'};
    my $inode_file = $self->{'inode'}->open($O_RDONLY);

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'inode' => $self,
        'max'   => $dev_flags->{'bucket_max'},
        'dir'   => $dev_flags->{'bucket_dir'}
    );

    while ( my $len = $inode_file->read( my $buf, 4096 ) ) {
        $bucket->write( $buf, $len );
    }

    $inode_file->close;
    $bucket->close;

    return $bucket;
}

sub directory {
    my ($self) = @_;

    throw &Errno::ENOTDIR unless $self->dir;

    unless ( $self->{'directory'} ) {
        $self->{'directory'} = $self->_copy_dir( $self->{'inode'}->directory );
    }

    return $self->{'directory'};
}

sub open {
    my ( $self, $flags ) = @_;

    unless ( $self->{'bucket'} ) {
        if ( $self->file && $flags & ( $O_WRONLY | $O_RDWR ) ) {
            $self->{'bucket'} = $self->_copy_file;
        }
    }

    if ( $self->{'bucket'} ) {
        return $self->{'bucket'}->open($flags);
    }

    return $self->{'inode'}->open($flags);
}

1;
