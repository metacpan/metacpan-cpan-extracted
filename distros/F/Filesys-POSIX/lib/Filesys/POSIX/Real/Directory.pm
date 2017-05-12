# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Real::Directory;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Directory ();

use Errno qw(ENOENT);

our @ISA = qw(Filesys::POSIX::Directory);

sub new {
    my ( $class, $path, $inode ) = @_;

    return bless {
        'path'     => $path,
        'inode'    => $inode,
        'mtime'    => 0,
        'overlays' => {},
        'detached' => {},
        'skipped'  => {},
        'members'  => {
            '.' => $inode,
            '..' => $inode->{'parent'} ? $inode->{'parent'} : $inode
        }
    }, $class;
}

sub _sync_all {
    my ($self) = @_;
    my $mtime = ( lstat $self->{'path'} )[9] or Carp::confess("$!");

    return unless $mtime > $self->{'mtime'};

    $self->open;

    # This uses readdir to bypass the aliased/detached overlays
    while ( my $item = readdir $self->{'dh'} ) {
        $self->_sync_member($item);
    }

    $self->close;

    $self->{'mtime'} = $mtime;
}

sub _sync_member {
    my ( $self, $name ) = @_;
    my $subpath = "$self->{'path'}/$name";
    my @st      = lstat $subpath;

    if ( scalar @st == 0 && $!{'ENOENT'} ) {
        delete $self->{'members'}->{$name};
        return;
    }

    Carp::confess("$!") unless @st;

    if ( exists $self->{'members'}->{$name} ) {
        $self->{'members'}->{$name}->update(@st);
    }
    else {
        $self->{'members'}->{$name} = Filesys::POSIX::Real::Inode->from_disk(
            $subpath,
            'st_info' => \@st,
            'dev'     => $self->{'inode'}->{'dev'},
            'parent'  => $self->{'inode'}
        );
    }
}

sub get {
    my ( $self, $name ) = @_;
    return undef if ( exists $self->{'detached'}->{$name} );

    return $self->{'overlays'}->{$name} if ( exists $self->{'overlays'}->{$name} );

    $self->_sync_member($name) unless exists $self->{'members'}->{$name};
    return $self->{'members'}->{$name};
}

sub set {
    my ( $self, $name, $inode ) = @_;
    delete $self->{'detached'}->{$name};
    $self->{'overlays'}->{$name} = $inode;
    return $inode;
}

sub rename_member {
    my ( $self, undef, $olddir, $oldname, $newname ) = @_;

    # TODO: This operation has no awareness of aliasing and detaching
    return rename( $olddir->path . '/' . $oldname, $self->path . '/' . $newname )
      && do {
        $olddir->_sync_member($oldname);
        $self->_sync_member($newname);
        1;
      };
}

sub exists {
    my ( $self, $name ) = @_;
    return '' if exists $self->{'detached'}->{$name};
    return 1  if exists $self->{'overlays'}->{$name};

    $self->_sync_member($name);
    return exists $self->{'members'}->{$name};
}

sub delete {
    my ( $self, $name ) = @_;

    if ( exists $self->{'detached'}->{$name} ) {
        return delete $self->{'detached'}->{$name};
    }

    if ( exists $self->{'overlays'}->{$name} ) {
        return delete $self->{'overlays'}->{$name};
    }

    my $member = $self->{'members'}->{$name} or return;
    my $subpath = "$self->{'path'}/$name";

    if ( $member->dir ) {
        rmdir($subpath);
    }
    else {
        unlink($subpath);
    }

    if ($!) {
        Carp::confess("$!") unless $!{'ENOENT'};
    }

    my $now = time;
    @{ $self->{'inode'} }{qw(mtime ctime)} = ( $now, $now );

    my $inode = $self->{'members'}->{$name};
    delete $self->{'members'}->{$name};

    return $inode;
}

sub detach {
    my ( $self, $name ) = @_;

    return undef if ( exists $self->{'detached'}->{$name} );

    $self->{'detached'}->{$name} = undef;

    foreach my $table (qw(members overlays)) {
        next unless exists $self->{$table}->{$name};

        return $self->{$table}->{$name};
    }
}

sub list {
    my ( $self, $name ) = @_;
    $self->_sync_all;

    my %union = ( %{ $self->{'members'} }, %{ $self->{'overlays'} } );

    delete @union{ keys %{ $self->{'detached'} } };

    return keys %union;
}

sub count {
    scalar( shift->list );
}

sub open {
    my ($self) = @_;

    @{ $self->{'skipped'} }{ keys %{ $self->{'overlays'} } } =
      values %{ $self->{'overlays'} };

    $self->close;

    opendir( $self->{'dh'}, $self->{'path'} ) or Carp::confess("$!");

    return $self;
}

sub rewind {
    my ($self) = @_;

    @{ $self->{'skipped'} }{ keys %{ $self->{'overlays'} } } =
      values %{ $self->{'overlays'} };

    if ( $self->{'dh'} ) {
        rewinddir $self->{'dh'};
    }

    return;
}

sub read {
    my ($self) = @_;
    my $item;

    do {
        if ( $self->{'dh'} ) {
            $item = readdir $self->{'dh'};
        }

        if ( defined $item ) {
            delete $self->{'skipped'}->{$item};
        }
        else {
            $item = each %{ $self->{'skipped'} };
        }
    } while ( $item && exists $self->{'detached'}->{$item} );

    if (wantarray) {
        return ( $item, $self->get($item) );
    }

    return $item;
}

sub close {
    my ($self) = @_;

    if ( $self->{'dh'} ) {
        closedir $self->{'dh'};
        delete $self->{'dh'};
    }

    return;
}

sub path {
    my ($self) = @_;
    return $self->{'path'};
}

1;
