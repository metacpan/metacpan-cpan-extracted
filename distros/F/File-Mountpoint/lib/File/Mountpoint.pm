# Copyright (c) 2008  Joshua Hoblitt
#
# $Id: Mountpoint.pm,v 1.5 2008/09/30 06:58:06 jhoblitt Exp $

package File::Mountpoint;

use strict;

our $VERSION = '0.01';

use base qw( Exporter );

use Carp;
use File::stat qw( :FIELDS );
use Fcntl qw( :mode );
use File::Spec;

our @EXPORT_OK = qw( is_mountpoint );

sub is_mountpoint
{
# running mountpoint on /tmp yields:
#   lstat("/tmp", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=28672, ...}) = 0
#   stat("/tmp/..", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
# running mountpoint on /tmp/ yields:
#   lstat("/tmp/", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=28672, ...}) = 0
#   stat("/tmp//..", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0

# $ mountpoint /tmp/asdf
# mountpoint: /tmp/asdf: No such file or directory
# $ mountpoint /tmp/binutils-2.18.tar.bz2 
# mountpoint: /tmp/binutils-2.18.tar.bz2: not a directory
# $ mountpoint /tmp                       
# /tmp is not a mountpoint

    my $path = shift;

    return unless defined $path;

    # verbose - currnetly unused
    my $verbose;

    # run lstat() on the path
    my $ls = lstat($path);

    # check to see if the path exists
    unless (defined $ls) {
        croak "is_mountpoint: $path: No such file or directory";
    }

    # check to make sure that the path exists and is a directory
    unless (S_ISDIR($st_mode)) {
        croak "is_mountpoint: $path: not a directory";
    }

    # store the lstat() device and inode
    my $ls_dev = $st_dev;
    my $ls_ino = $st_ino;

    # append /.. to the path and run stat() on it
    stat(File::Spec->catdir($path, "/.."));

    # store the stat() device
    my $s_dev = $st_dev;
    my $s_ino = $st_ino;

    # compare the lstat() and stat() devs
# based directly on code from mountpoint.c
    unless (($ls_dev != $s_dev) || ($ls_dev == $s_dev && $ls_ino == $s_ino)) {
        carp "is_mounpoint: $path is not a mountpoint" if $verbose;
        return;
    }

    return 1;
}


1;

__END__


=pod

=head1 NAME

File::Mountpoint - see if a directory is a mountpoint

=head1 SYNOPSIS

    use File::Mountpoint;

    if (File::Mountpoint::is_mountpoint("/foo/bar")) {
        ...
    }

    or

    use File::MountPoint qw( is_mountpoint );

    if (is_mountpoint("/foo/bar")) {
        ...
    }

=head1 DESCRIPTION

This module provides a single function, C<is_mountpoint()>, that can be used to
tell if a directory path on a I<POSIX> filesystem is the point at which a
volume is mounted.

=head1 USAGE

=head2 Import Parameters

This module accepts I<symbol> names to be exported to it's C<import> method.

    use File::MountPoint qw( is_mountpoint );

=head2 Functions

=over 4

=item * C<is_mountpoint($path)>

Accepts a single scalar parameter which is the path (must be a directory) to be tested.

This function will C<die> if C<$path> does not exist or is not a directory.

Returns true on success and fails with C<undef> in scalar context or C<()> in list context.

=back

=head1 REFERENCES

=over 4

=item mountpoint

This module is based on the behavior of the C<mountpoint> utility that is included with the sysvinit package.

L<http://freshmeat.net/redir/sysvinit/10192/url_tgz/sysvinit>

=back

=head1 CREDITS

Miquel van Smoorenburg, miquels@cistron.nl, author of the C<sysvinit> package.

Me, myself, and I.

=head1 SUPPORT

Please contact the author directly via e-mail.

=head1 AUTHOR

Joshua Hoblitt <jhoblitt@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2008  Joshua Hoblitt.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA  02111-1307, USA.

The full text of the license can be found in the LICENSE file included with
this module, or in the L<perlgpl> Pod as supplied with Perl 5.8.1 and later.

=head1 SEE ALSO

C<mountpoint>

=cut
