# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Userland::Tar;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module ();

use Filesys::POSIX::Path                  ();
use Filesys::POSIX::Userland::Find        ();
use Filesys::POSIX::Userland::Tar::Header ();

use Errno;
use Carp ();

my @METHODS = qw(tar);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Userland::Tar - Generate ustar archives from L<Filesys::POSIX>

=head1 SYNOPSIS

    use Filesys::POSIX;
    use Filesys::POSIX::Mem;
    use Filesys::POSIX::IO::Handle;
    use Filesys::POSIX::Userland::Tar;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Mem->new,
        'noatime' => 1
    );

    $fs->mkdir('foo');
    $fs->touch('foo/bar');

    $fs->tar(Filesys::POSIX::IO::Handle->new(\*STDOUT), '.');

=head1 DESCRIPTION

This module provides an implementation of the ustar standard on top of the
virtual filesystem layer, a mechanism intended to take advantage of the many
possible mapping and manipulation capabilities inherent in this mechanism.
Internally, it uses the L<Filesys::POSIX::Userland::Find> module to perform
depth- last recursion to locate inodes for packaging.

As mentioned, archives are written in the ustar format, with pathnames of the
extended maximum length of 256 characters, supporting file sizes up to 4GB.
Currently, only user and group IDs are stored; names are not resolved and
stored as of the time of this writing.  All inode types are supported for
archival.

=head1 USAGE

=over

=cut

our $BLOCK_SIZE = 512;
our $BUF_MAX    = 20 * $BLOCK_SIZE;

#
# NOTE: I'm only using $inode->open() calls to avoid having to call stat().
# This is not necessarily something that should be done by end user software.
#
sub _write_file {
    my ( $fh, $inode, $handle, $size ) = @_;

    my $total           = 0;
    my $actual_file_len = 0;

    my $premature_eof;

    do {
        my $max_read = $size - $actual_file_len;
        $max_read = $BUF_MAX if $max_read > $BUF_MAX;

        my ( $len, $real_len, $buf );
        if ($premature_eof) {    # If we reach EOF before the expected length, pad with null bytes
            $len = $real_len = $max_read;
            $buf = "\x0" x $max_read;
        }
        else {
            $buf      = '';
            $real_len = 0;
            my $amt_read;

            # Attempt to read a total of $max_read bytes per buffer. ($max_read is either the
            # maximum buffer size or the number of bytes expected remaining in the file, whichever
            # is smaller.)
            #
            # Possible outcomes:
            #
            #   1. We received no bytes, in which case we have reached EOF unexpectedly.
            #      Produce a warning and set the flag to pad the remaining portion of the
            #      file with null bytes.
            #   2. We received exactly $max_read bytes. This is good and means we can drop out of
            #      this sub-loop after a single iteration per read loop iteration. (Should be the
            #      most common case.)
            #   3. We received some bytes, but not as many as we expected. Retry the read,
            #      accumulating bytes until we either have a total of $max_read bytes for
            #      this block or we reach EOF.
            do {
                my $incremental_buf;
                $amt_read = $fh->read( $incremental_buf, $max_read - $real_len );
                $buf .= $incremental_buf;
                $real_len += $amt_read;

                if ( $amt_read <= 0 && $max_read - $real_len > 0 ) {
                    $premature_eof = 1;
                    warn sprintf(
                        'WARNING: Short read while archiving file (expected total of %d bytes, but only got %d); padding with null bytes...',
                        $size, $actual_file_len + $real_len,
                    );
                }
            } while ( $real_len < $max_read && $amt_read > 0 );

            $len = $real_len;
        }

        if ( ( my $padlen = $BLOCK_SIZE - ( $len % $BLOCK_SIZE ) ) != $BLOCK_SIZE ) {
            $len += $padlen;
            $buf .= "\x0" x $padlen;
        }

        my $written = 0;

        if ( ( $written = $handle->write( $buf, $len ) ) != $len ) {
            Carp::confess("Short write while dumping file buffer to handle. Expected to write $len bytes, but only wrote $written.");
        }

        $actual_file_len += $real_len;
        $total           += $written;
    } while ( $actual_file_len < $size );

    $fh->close;

    return $total;
}

sub _archive {
    my ( $inode, $handle, $path, $opts ) = @_;

    my $written = 0;

    my $header = Filesys::POSIX::Userland::Tar::Header->from_inode( $inode, $path );
    my $blocks = '';

    if ( $header->{'truncated'} ) {

        if ( $opts->{'gnu_extensions'} ) {
            $blocks .= $header->encode_longlink;
        }
        elsif ( $opts->{'posix_extensions'} ) {
            $blocks .= $header->encode_posix;
        }
        else {
            die('Filename too long');
        }
    }

    $blocks .= $header->encode;
    local $@;

    eval {
        # Acquire the file handle before writing the header so we don't corrupt
        # the tarball if the file is missing.
        my $fh;

        if ( $inode->file && $header->{'size'} > 0 ) {
            $fh = $inode->open( $O_RDONLY | $O_NONBLOCK );    # Case 82969: No block on pipes
        }

        # write header
        my $header_len = length $blocks;
        unless ( $handle->write( $blocks, $header_len ) == $header_len ) {
            Carp::confess('Short write while dumping tar header to file handle');
        }
        $written += $header_len;

        # write file
        $written += _write_file( $fh, $inode, $handle, $header->{'size'} ) if ($fh);
    };

    if ($!) {
        if ( $! == &Errno::ENOENT && $opts->{'ignore_missing'} ) {
            $opts->{'ignore_missing'}->($path)
              if ref $opts->{'ignore_missing'} eq 'CODE';
        }
        elsif ( $! == &Errno::EACCES && $opts->{'ignore_inaccessible'} ) {
            $opts->{'ignore_inaccessible'}->($path)
              if ref $opts->{'ignore_inaccessible'} eq 'CODE';
        }
        else {
            die $@;
        }
    }

    return $written;
}

=item C<$fs-E<gt>tar($handle, @items)>

=item C<$fs-E<gt>tar($handle, $opts, @items)>

Locate files and directories in each path specified in the C<@items> array,
writing results to the I/O handle wrapper specified by C<$handle>, an instance
of L<Filesys::POSIX::IO::Handle>.  When an anonymous HASH argument, C<$opts>, is
specified, the data is passed unmodified to L<Filesys::POSIX::Userland::Find>.
In this way, for instance, the behavior of following symlinks can be specified.

In addition to options supported by L<Filesys::POSIX::Userland::Find>, the
following options are recognized uniquely by C<$fs-E<gt>tar()>:

=over

=item C<gnu_extensions>

When set, certain GNU extensions to the tar output format are enabled, namely
support for arbitrarily long filenames.

=item C<ignore_missing>

When set, ignore if a file is missing when writing it to the tarball.  This can
happen if a file is removed between the time the find functionality finds it and
the time it is actually written to the output.  If the value is a coderef, calls
that function with the name of the missing file.

=item C<ignore_inaccessible>

When set, ignore if a file is unreadable when writing it to the tarball.  This can
happen if a file permissions do not allow the current UID and GID to read the file.
If the value is a coderef, calls that function with the name of the inaccessible
file.

=back

=cut

sub tar {
    my $self     = shift;
    my $handle   = shift;
    my $opts     = ref $_[0] eq 'HASH' ? shift : {};
    my @items    = @_;
    my $unpadded = 0;

    $self->find(
        sub {
            my ( $path, $inode ) = @_;

            return if $inode->sock;

            $unpadded += _archive( $inode, $handle, $path->full, $opts );
            $unpadded %= $BUF_MAX;
        },
        $opts,
        @items
    );

    my $padlen = $BUF_MAX - ( $unpadded % $BUF_MAX );
    $handle->write( "\x00" x $padlen, $padlen );

    return;
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

=item John Lightsey <jd@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
