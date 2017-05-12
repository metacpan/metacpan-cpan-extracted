# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::VFS;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Path       ();
use Filesys::POSIX::VFS::Inode ();

use Filesys::POSIX::Error qw(throw);

sub new {
    return bless {
        'mounts'  => [],
        'devices' => {},
        'vnodes'  => {}
      },
      shift;
}

sub statfs {
    my ( $self, $start, %opts ) = @_;
    my $inode = $start;
    my $ret;

    while ( $inode->{'vnode'} ) {
        $inode = $inode->{'vnode'};
    }

    if ( $opts{'exact'} ) {
        $ret = $self->{'vnodes'}->{$inode};
    }
    else {
        $ret = $self->{'devices'}->{ $inode->{'dev'} };
    }

    unless ($ret) {
        throw &Errno::ENXIO unless $opts{'silent'};
    }

    return $ret;
}

sub mountlist {
    my ($self) = @_;
    return @{ $self->{'mounts'} };
}

#
# It should be noted that any usage of pathnames in this module are entirely
# symbolic and are not used for canonical purposes.  The higher-level
# filesystem layer should take on the responsibility of providing both the
# canonically-correct absolute pathnames for mount points, and helping locate
# the appropriate VFS mount point for querying purposes.
#
sub mount {
    my ( $self, $dev, $path, $mountpoint, %data ) = @_;

    if ( grep { $_->{'dev'} eq $dev } @{ $self->{'mounts'} } ) {
        throw &Errno::EBUSY;
    }

    $data{'special'} ||= scalar $dev;

    #
    # Generate a generic BSD-style filesystem type string.
    #
    my $type = lc ref $dev;
    $type =~ s/^([a-z_][a-z0-9_]*::)*//;

    #
    # Create a vnode record munged from the mountpoint and new
    # filesystem root.
    #
    my $vnode = Filesys::POSIX::VFS::Inode->new( $mountpoint, $dev->{'root'} );

    #
    # Associate the mountpoint and filesystem roots with this vnode.
    #
    $mountpoint->{'vnode'} = $vnode;
    $dev->{'root'}->{'vnode'} = $vnode;

    #
    # Generate the mount record.
    #
    my $mount = {
        'mountpoint' => $mountpoint,
        'root'       => $dev->{'root'},
        'special'    => $data{'special'},
        'dev'        => $dev,
        'type'       => $type,
        'path'       => $path,
        'vnode'      => $vnode,

        'flags' => { map { $_ => $data{$_} } grep { $_ ne 'special' } keys %data }
    };

    #
    # Store the mount record in the ordered mount list.
    #
    push @{ $self->{'mounts'} }, $mount;

    #
    # Associate the vnode with the mount rcord.
    #
    $self->{'vnodes'}->{$vnode} = $mount;

    #
    # Finally, associate the filesystem with the mount record.
    #
    $self->{'devices'}->{$dev} = $mount;

    return $self;
}

sub vnode {
    my ( $self, $start ) = @_;
    my $inode = $start;

    return undef unless $inode;

    while ( $inode->{'vnode'} ) {
        $inode = $inode->{'vnode'};
    }

    my $mount = $self->{'devices'}->{ $inode->{'dev'} };

    if ( $mount->{'flags'}->{'noexec'} ) {
        $inode->{'mode'} &= ~$S_IX;
    }

    if ( $mount->{'flags'}->{'nosuid'} ) {
        $inode->{'mode'} &= ~$S_ISUID;
    }

    foreach (qw(uid gid)) {
        if ( defined $mount->{'flags'}->{$_} ) {
            $inode->{$_} = $mount->{'flags'}->{$_};
        }
    }

    return $inode;
}

sub unmount {
    my ( $self, $mount ) = @_;

    #
    # First, check to see that the filesystem mount record found is a
    # dependency for another mounted filesystem.
    #
    foreach ( @{ $self->{'mounts'} } ) {
        next if $_ == $mount;

        throw &Errno::EBUSY if $_->{'mountpoint'}->{'dev'} == $mount->{'dev'};
    }

    #
    # Pluck the filesystem from the mount list.
    #
    for ( my $i = 0; $self->{'mounts'}->[$i]; $i++ ) {
        next unless $self->{'mounts'}->[$i] eq $mount;
        splice @{ $self->{'mounts'} }, $i;
        last;
    }

    #
    # Untie the vnode reference from its original mount point and root.
    #
    delete $mount->{'mountpoint'}->{'vnode'};
    delete $mount->{'root'}->{'vnode'};

    #
    # Break references to the mount record from the per-vnode hash.
    #
    delete $self->{'vnodes'}->{ $mount->{'vnode'} };

    #
    # Kill references to the mount record from the per-device hash.
    #
    delete $self->{'devices'}->{ $mount->{'dev'} };

    return $self;
}

1;
