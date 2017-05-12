#============================================================= -*-perl-*-
#
# File::RsyncP::FileList package
#
# DESCRIPTION
#   File::RsyncP::FileList is a perl module that implements the
#   file list encoding and decoding used by rsync.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   File::RsyncP is Copyright (C) 2002-2015  Craig Barratt.
#
#   Rsync is Copyright (C) 1996-2001 by Andrew Tridgell, 1996 by Paul
#   Mackerras, 2001-2002 by Martin Pool, and 2003-2009 by Wayne Davison,
#   and others.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#========================================================================
#
# Version 0.74, released 17 Jan 2015.
#
# See http://perlrsync.sourceforge.net.
#
#========================================================================

package File::RsyncP::FileList;

use strict;

require Exporter;
require DynaLoader;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);
@ISA = qw(Exporter AutoLoader DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use File::RsyncP::FileList ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.74';

bootstrap File::RsyncP::FileList $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

File::RsyncP::FileList - Perl interface to rsync file list encoding and
decoding.

=head1 SYNOPSIS

    use File::RsyncP::FileList;

    $fileList = File::RsyncP::FileList->new({
        preserve_uid        => 1,
        preserve_gid        => 1,
        preserve_links      => 1,
        preserve_devices    => 1,
        preserve_hard_links => 0,
        always_checksum     => 0,
        remote_version      => 26,
    });

    # decoding an incoming file list
    while ( !$fileList->decodeDone && !$fileList->fatalError ) {
        $data .= readMoreDataFromRemoteRsync();
        $bytesDone = $fileList->decode($data);
        $data = substr($data, $bytesDone) if ( $bytesDone > 0 );
    }
    $fileList->clean;

    # create (encode) a file list
    $fileList->encode({
            name  => $filePath,
            dev   => $stat[0],
            inode => $stat[1],
            mode  => $stat[2],
            uid   => $stat[4],
            gid   => $stat[5],
            rdev  => $stat[6],
            mtime => $stat[9],
        });
    $data = $fileList->encodeData;

    # get file information, for file number 5:
    $fileInfo = $fileList->get(5);

    # utility functions
    $numberOfFiles = $fileList->count;
    $gotFatalError = $fileList->fatalError;

=head1 DESCRIPTION

The File::RsyncP::FileList module is used to encode and decode file
lists in using the same format at Rsync.

The sender side of Rsync creates a list of all the files the are
going to be sent.  This list is sent in a compact format to
the receiver side.  Each side then sorts the list and removes
duplicate entries.  From this point on, all files are referred
to by their integer index into the sorted file list.

A new file list object is created by calling File::RsyncP::FileList->new.
An object can be used to decode or encode a file list.  There is no
mechanism to reset the state of a file list: you should create a new
object each time you need to do a new decode or encode.

The new() function takes a hashref of options, which correspond to
various rsync command-line switches.  These must exactly match the
arguments to the remote rsync, otherwise the file list format will
not be compatible and decoding will fail.

    $fileList = File::RsyncP::FileList->new({
        preserve_uid        => 1,       # --owner
        preserve_gid        => 1,       # --group
        preserve_links      => 1,       # --links
        preserve_devices    => 1,       # --devices
        preserve_hard_links => 0,       # --hard-links
        always_checksum     => 0,       # --checksum
        remote_version      => 26,      # remote protocol version
    });

=head2 Decoding

The decoding functions take a stream of bytes from the remote rsync
and convert them into an internal data structure.  Rather than store
the file list as a native perl list of hashes (which occupies too much
memory for large file lists), the same internal data structure as rsync
is used.  Individual file list entries can be returned with the get()
function.

File list data read from the remote rsync should be passed to the
decode() function.  The data may be read and processed in arbitrary
sized chunks.  The decode() function returns how many bytes were
actually processed.  It is the caller's responsbility to remove that
number of bytes from the input argument, preserving the remaining bytes
for the next call to decode().  The decodeDone() function returns true when
the file list is complete.  The fatalError() function returns true if
there was a non-recoverable error while decoding.

The clean() function needs to be called after the file list decode is
complete.  The clean() function sorts the file list and removes
repeated entries.  Skipping this step will produce unexpected results:
since files are referred to using integers, each side will refer to
different files is the file lists are not sorted and purged in exactly
the same manner.

A typical decode loop looks like:

    while ( !$fileList->decodeDone && !$fileList->fatalError ) {
        $data .= readMoreDataFromRemoteRsync();
        $bytesDone = $fileList->decode($data);
        $data = substr($data, $bytesDone) if ( $bytesDone > 0 );
    }
    $fileList->clean;

After clean() is called, the number of files in the file list can be
found by calling count().  Files can be fetched by calling the get()
function, with an index from 0 to count()-1:

    $fileInfo = $fileList->get(5);

The get() function returns a hashref with various entries:

        name      path name of the file (relative to rsync dir):
                  equal to dirname/basename
        basename  file name, without directory
        dirname   directory where file resides
        sum       file MD4 checksum (only present if --checksum specified)
        uid       file user id
        gid       file group id
        mode      file mode
        mtime     file modification time
        size      file length
        dev       device number on which file resides
        inode     file inode
        link      link contents if the file is a sym link
        rdev      major/minor device number if file is char/block special

Various fields will only have valid values if the corresponding options are
set (eg: uid if preserve_uid is set, dev and inode if preserve_hard_links
is set etc).

For example, to dump out each of hash you could do this:

    use Data::Dumper;
    my $count = $fileList->count;
    for ( my $i = 0 ; $i < $count ; $i++ ) {
        print("File $i is:\n");
        print Dumper($fileList->get($i));
    }

=head2 Encoding

The encode() function is used to build a file list in preparation for
encoding and sending a file list to a remote rsync.  The encode()
function takes a hashref argument with the parameters for one file.
It should be called once for each file.  The parameter names are the
same as those returned by get().

In this example the matching stat() values are shown:

    $fileList->encode({
            name  => $filePath,
            dev   => $stat[0],
            inode => $stat[1],
            mode  => $stat[2],
            uid   => $stat[4],
            gid   => $stat[5],
            rdev  => $stat[6],
            size  => $stat[7],
            mtime => $stat[9],
        });

It is not necessary to specify basename and dirname; these are extracted
from name.  You only need to specify the parameters that match the
options given to new().  You can also specify sum and link as necessary.

To compute the encoded file list data the encodeData() function should
be called.  It can be called every time encode() is called, or once
at the end of all the encode() calls.  It returns the encoded data
that should be sent to the remote rsync:

    $data = $fileList->encodeData;

It is recommended that encodeData() be called frequently to avoid the
need to allocate large internal buffers to hold the entire encoded 
file list.  Since encodeData() does not know when the last file
has been encoded, it is the caller's responsbility to add the
final null byte (eg: pack("C", 0)) to the data to indicate the
end of the file list data.

After all the file list entries are processed you should call clean():

    $fileList->clean;

This ensures that each side (sender/receiver) has identical sorted
file lists.

=head2 Utility functions

The count() function returns the total number of files in the internal
file list (either decoded or encoded).

The fatalError() function returns true if a fatal error has occured
during file decoding.  It should be called in the decode loop to 
make sure no error has occured.

=head1 AUTHOR

File::RsyncP::FileList was written by Craig Barratt
<cbarratt@users.sourceforge.net> based on rsync 2.5.5.

Rsync was written by Andrew Tridgell <tridge@samba.org>
and Paul Mackerras.  It is available under a GPL license.
See http://rsync.samba.org

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License in the
LICENSE file along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.

=head1 SEE ALSO

See L<http://perlrsync.sourceforge.net> for File::RsyncP's SourceForge
home page.

See L<File::RsyncP> and L<File::RsyncP::FileIO> for more
precise examples of using L<File::RsyncP::FileList>.

Also see BackupPC's lib/BackupPC/Xfer/RsyncFileIO.pm for other examples.

=cut
