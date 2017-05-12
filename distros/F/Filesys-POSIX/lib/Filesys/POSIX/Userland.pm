# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Userland;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module ();
use Filesys::POSIX::Path   ();

use Carp qw(confess);

my @METHODS = qw(
  _find_inode_path mkpath getcwd realpath opendir readdir closedir touch
);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Userland - Provide implementations for higher-level, "userland"
functionality in L<Filesys::POSIX>

=head1 DESCRIPTION

This module is a mixin imported by L<Filesys::POSIX> into its own namespace, and
provides a variety of higher-level calls to supplement the normal suite of
system calls provided in L<Filesys::POSIX> itself.

=head1 METHODS

=over

=cut

sub _find_inode_path {
    my ( $self, $start ) = @_;
    my $inode = $self->{'vfs'}->vnode($start);
    my @ret;

    while ( my $dir = $self->{'vfs'}->vnode($inode)->{'parent'} ) {
        my $directory = $dir->directory;

        foreach my $item ( $directory->list ) {
            next if $item eq '.' || $item eq '..';
            next
              unless $self->{'vfs'}->vnode( $directory->get($item) ) == $self->{'vfs'}->vnode($inode);

            push @ret, $item;
            $inode = $dir;
        }
    }

    return '/' . join( '/', reverse @ret );
}

=item C<$fs-E<gt>mkpath($path)>

=item C<$fs-E<gt>mkpath($path, $mode)>

Similar to the C<-p> flag that can be passed to L<mkdir(1)>, this
method attempts to create a hierarchy of directories specified in C<$path>.
Each path component created will be made with the mode specified by C<$mode>, if
any, if a directory in that location does not already exist.  Exceptions will be
thrown if one of the items along the path hierarchy exists but is not a
directory.

A default mode of 0777 is assumed; only the permissions field of C<$mode> is
used when it is specified.  In both cases, the mode specified is modified with
exclusive OR by the current umask value.

=cut

sub mkpath {
    my ( $self, $path, $mode ) = @_;
    my $perm = $mode ? $mode & ( $S_IPERM | $S_IPROT ) : $S_IPERM ^ $self->{'umask'};
    my $hier = Filesys::POSIX::Path->new($path);
    my $dir  = $self->{'cwd'};

    while ( $hier->count ) {
        my $item = $hier->shift;

        unless ($item) {
            $dir = $self->{'root'};
            next;
        }

        my $directory = $dir->directory;
        my $inode     = $self->{'vfs'}->vnode( $directory->get($item) );

        if ($inode) {
            $dir = $inode;
        }
        else {
            $dir = $dir->child( $item, $perm | $S_IFDIR );
        }
    }

    return $dir;
}

=item C<$fs-E<gt>getcwd>

Returns a string representation of the current working directory.

=cut

sub getcwd {
    my ($self) = @_;

    return $self->_find_inode_path( $self->{'cwd'} );
}

=item C<$fs-E<gt>realpath($path)>

Returns a string representation of the full, true and original path of the
inode specified by C<$path>.

Using C<$fs-E<gt>stat>, the inode of C<$path> is resolved, then starting at that
inode, each subsequent inode's name is found from its parent and appended to a
list of path components.  

=cut

sub realpath {
    my ( $self, $path ) = @_;
    my $inode = $self->stat($path);

    return $self->_find_inode_path($inode);
}

=item C<$fs-E<gt>opendir($path)>

Returns a newly opened directory handle for the item pointed to by C<$path>.
Using other methods in this module, the directory can be read and closed.

=cut

sub opendir {
    my ( $self, $path ) = @_;

    my $directory = $self->stat($path)->directory;
    $directory->open;

    return $directory;
}

=item C<$fs-E<gt>readdir($directory)>

Read the next member of the directory passed.  Returns undef if there are no
more entries to be read.

=cut

sub readdir {
    my ( $self, $directory ) = @_;

    return $directory->read unless wantarray;

    my @ret;

    while ( defined( my $item = $directory->read ) ) {
        push @ret, $item;
    }

    return @ret;
}

=item C<$fs-E<gt>closedir($directory)>

Closes the directory handle for reading.

=cut

sub closedir {
    my ( $self, $directory ) = @_;
    return $directory->close;
}

=item C<$fs-E<gt>touch($path)>

Acts like the userland utility L<touch()|perlfunc/touch>.  Uses C<$fs-E<gt>open>
with the C<$O_CREAT> flag to open the file specified by C<$path>, and
immediately closes the file descriptor returned.  This causes an update of the
inode modification time for existing files, and the creation of new, empty files
otherwise.

=cut

sub touch {
    my ( $self, $path ) = @_;
    my $fd = $self->open( $path, $O_CREAT );
    my $inode = $self->fstat($fd);

    $self->close($fd);

    return $inode;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
