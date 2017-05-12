# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Mem         ();
use Filesys::POSIX::Mem::Inode  ();
use Filesys::POSIX::Mem::Bucket ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 56 );
use Test::Exception;
use Test::Filesys::POSIX::Error;
use Test::NoWarnings;

{
    my $inode = Filesys::POSIX::Mem::Inode->new(
        'mode' => 0644,
        'dev'  => Filesys::POSIX::Mem->new
    );

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'inode' => $inode,
        'max'   => 0,
        'dir'   => '.'
    );

    $bucket->open($O_RDWR);

    is(
        $bucket->write( 'foo', 3 ),
        3,
        "Filesys::POSIX::Mem::Bucket->write() returns expected write length"
    );

    throws_errno_ok {
        $bucket->_flush_to_disk(3);
    }
    &Errno::EALREADY, "Filesys::POSIX::Mem::Bucket->_flush_to_disk() cannot be repeated";

    my ( $file, $handle ) = @{$bucket}{qw(file fh)};

    ok(
        -f $file,
        "Filesys::POSIX::Mem::Bucket->write() flushes to disk immediately with a max of 0"
    );
    ok(
        $bucket->seek( 0, $SEEK_SET ) == 0,
        "Filesys::POSIX::Mem::Bucket->seek() functions and returns expected offset"
    );
    is(
        $bucket->read( my $buf, 3 ),
        3, "Filesys::POSIX::Mem::Bucket->read() reports expected read length"
    );
    is(
        $buf, 'foo',
        "Filesys::POSIX::Mem::Bucket->read() populated buffer with expected contents"
    );
    is(
        $bucket->tell, 3,
        "Filesys::POSIX::Mem::Bucket->tell() reports expected offset"
    );
    is(
        $bucket->seek( 0, $SEEK_CUR ),
        3,
        "Filesys::POSIX::Mem::Bucket->seek(0, \$SEEK_CUR) operates expectedly"
    );
    is(
        $bucket->seek( 3, $SEEK_CUR ),
        6,
        "Filesys::POSIX::Mem::Bucket->seek(3, \$SEEK_CUR) operates expectedly"
    );

    throws_errno_ok {
        $bucket->open(0);
    }
    &Errno::EBUSY, "Filesys::POSIX::Mem::Bucket->open() will throw 'Already opened' when appropriate";

    $bucket->close;

    ok(
        !defined fileno($handle),
        "Filesys::POSIX::Mem::Bucket->close() closes internal file handle"
    );
    ok(
        !defined $bucket->{'fh'},
        "Filesys::POSIX::Mem::Bucket->close() destroys internal file handle"
    );

    $bucket->open($O_APPEND);
    ok(
        $bucket->{'pos'} == $bucket->{'size'},
        "Filesys::POSIX::Mem::Bucket->open() honors \$O_APPEND"
    );

    $bucket->close;
    $bucket->open($O_TRUNC);
    ok(
        $bucket->{'pos'} == 0 && $bucket->{'size'} == 0,
        "Filesys::POSIX::Mem::Bucket->open() honors \$O_TRUNC"
    );

    undef $bucket;

    ok(
        !-f $file,
        "Filesys::POSIX::Mem::Bucket->DESTROY() reclaims disk file"
    );
}

{
    my $inode = Filesys::POSIX::Mem::Inode->new(
        'mode' => 0644,
        'dev'  => Filesys::POSIX::Mem->new
    );

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'inode' => $inode,
        'max'   => 0,
        'dir'   => '.'
    );

    $bucket->write( 'foo', 3 );

    my ( $file, $handle ) = @{$bucket}{qw(file fh)};
    undef $bucket;

    ok(
        !-f $file && !defined fileno($handle),
        "Filesys::POSIX::Mem::Bucket->DESTROY() calls close()"
    );
}

{
    my $inode = Filesys::POSIX::Mem::Inode->new(
        'mode' => 0644,
        'dev'  => Filesys::POSIX::Mem->new
    );

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'inode' => $inode,
        'max'   => 0,
        'dir'   => '.'
    );

    $bucket->write( 'foo', 3 );

    my ( $file, $handle ) = @{$bucket}{qw(file fh)};

    undef $bucket->{'file'};
    $bucket->close;

    ok(
        -f $file && !defined fileno($handle),
        "Filesys::POSIX::Mem::Bucket->close() only removes file it references"
    );

    unlink($file);
}

{
    my $inode = Filesys::POSIX::Mem::Inode->new(
        'mode' => 0644,
        'dev'  => Filesys::POSIX::Mem->new
    );

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'inode' => $inode,
        'max'   => 0,
        'dir'   => '.'
    );

    $bucket->write( 'foo', 3 );

    my ( $file, $handle ) = @{$bucket}{qw(file fh)};

    $bucket->close;
    unlink($file);

    throws_errno_ok {
        $bucket->open;
    }
    &Errno::ENOENT, "Filesys::POSIX::Mem::Bucket->open() will die when reopening missing bucket";
}

{
    my $inode = Filesys::POSIX::Mem::Inode->new(
        'mode' => 0644,
        'dev'  => Filesys::POSIX::Mem->new
    );

    my $bucket = Filesys::POSIX::Mem::Bucket->new( 'inode' => $inode );

    $bucket->write( 'foo', 3 );
    $bucket->close;
    $bucket->open($O_TRUNC);

    ok(
        $bucket->{'size'} == 0 && $bucket->{'pos'} == 0 && $inode->{'size'} == 0,
        "Filesys::POSIX::Mem::Bucket->open() respects \$O_TRUNC on memory buckets"
    );
}

{
    my $uid = $<;

    if ( $uid == 0 ) {
        $> = ( getpwnam 'nobody' )[2];
    }

    my $bucket = Filesys::POSIX::Mem::Bucket->new(
        'dir' => '/',
        'max' => 0
    );

    dies_ok {
        $bucket->write( 'foo', 3 );
    }
    "Filesys::POSIX::Mem::Bucket->_flush_to_disk() dies on bad mkstemp()";

    if ( $uid == 0 ) {
        $> = $uid;
    }
}

{
    my $bucket = Filesys::POSIX::Mem::Bucket->new( 'max' => 1024 );

    foreach ( 1 .. 192 ) {
        $bucket->write( 'meowcats', 8 );
    }

    is(
        $bucket->{'size'},
        192 * 8,
        "Filesys::POSIX::Mem::Bucket->_flush_to_disk() flushes when size exceeds max"
    );

    {
        my $read = 0;

        $bucket->seek( 0, $SEEK_SET );

        while ( my $len = $bucket->read( my $buf, 8 ) ) {
            $read += $len if $buf eq 'meowcats';
        }

        is(
            $read,
            192 * 8,
            "Filesys::POSIX::Mem::Bucket->read() fetches bucket data correctly after seek(0, 0)"
        );
    }

    {
        $bucket->seek( 0, $SEEK_SET );

        is(
            $bucket->read( my $buf, 192 * 9 ),
            192 * 8,
            "Filesys::POSIX::Mem::Bucket->read() restricts read max to position, minus size"
        );
    }

    close( $bucket->{'fh'} );

    throws_ok {
        $bucket->read( my $buf, 3 );
    }
    qr/^Unable to read bucket/, "Filesys::POSIX::Mem::Bucket->read() will die if sysread() dies";

    throws_ok {
        $bucket->write( 'foo', 3 );
    }
    qr/^Unable to write to disk bucket/, "Filesys::POSIX::Mem::Bucket->write() will die if syswrite() dies";
}

{
    my $bucket = Filesys::POSIX::Mem::Bucket->new( 'max' => 1024 );

    $bucket->open($O_RDWR);
    $bucket->seek( 2048, $SEEK_SET );

    is(
        $bucket->read( my $buf, 3 ),
        0,
        "Filesys::POSIX::Mem::Bucket->read() returns 0 when reading beyond size in memory buckets"
    );

    is(
        $bucket->seek( 2048, $SEEK_END ),
        2048,
        "Filesys::POSIX::Mem::Bucket->seek() with \$SEEK_END works properly"
    );

    is(
        $bucket->seek( 2048, $SEEK_CUR ),
        4096,
        "Filesys::POSIX::Mem::Bucket->seek() with \$SEEK_CUR works properly"
    );

    throws_errno_ok {
        $bucket->seek( 2048, 0x04 );
    }
    &Errno::EINVAL, "Filesys::POSIX::Mem::Bucket->seek() will die with 'Invalid argument' when appropriate";
}

{
    my $bucket = Filesys::POSIX::Mem::Bucket->new;

    $bucket->open( $O_RDWR | $O_TRUNC );

    $bucket->write( 'X' x 128, 128 );
    $bucket->write( 'O' x 128, 128 );

    $bucket->seek( 128, $SEEK_SET );

    my $len = $bucket->read( my $buf, 128 );

    is(
        $len, 128,
        "Filesys::POSIX::Mem::Bucket->read() after open(\$O_RDWR | \$O_TRUNC) returns correct number of bytes"
    );
    is(
        $buf,
        'O' x 128,
        "Filesys::POSIX::Mem::Bucket->read() after truncate open filled buffer appropriately"
    );
}

{
    my $bucket = Filesys::POSIX::Mem::Bucket->new;

    $bucket->open($O_WRONLY);
    $bucket->write( 'X' x 20480, 20480 );
    $bucket->close;

    $bucket->open( $O_WRONLY | $O_APPEND );
    $bucket->write( "foo\n", 4 );
    $bucket->close;

    $bucket->open($O_RDONLY);

    my $len = $bucket->read( my $buf, 20480 );

    is(
        $len, 20480,
        "First write() 20480 bytes written successfully to memory bucket"
    );
    ok(
        $buf eq 'X' x 20480,
        "Filesys::POSIX::Mem::Bucket->read() after two open() write calls returns expected result"
    );

    $len = $bucket->read( $buf, 512 );

    is(
        $len, 4,
        "Second write() of 4 bytes written successfully to memory bucket"
    );
    is(
        $buf, "foo\n",
        "Filesys::POSIX::Mem::Bucket->read() after two open() write calls returns expected second result"
    );

    $bucket->close;
}

#
# Ensure $O_CREAT and $O_TRUNC both truncate file data
#
{
    my %FLAGS = (
        '$O_CREAT' => $O_CREAT,
        '$O_TRUNC' => $O_TRUNC
    );

    foreach my $flag_name ( sort keys %FLAGS ) {
        my $bucket = Filesys::POSIX::Mem::Bucket->new;

        my $flag = $FLAGS{$flag_name};

        $bucket->open( $flag | $O_WRONLY );
        $bucket->write( 'X' x 1024, 1024 );
        $bucket->close;

        $bucket->open( $flag | $O_WRONLY );

        is(
            $bucket->{'size'}, 0,
            "Bucket size is 0 after second open() with $flag_name"
        );
        is(
            $bucket->{'pos'}, 0,
            "Bucket position is 0 after second open() with $flag_name"
        );

        $bucket->write( 'X' x 1024, 1024 );

        is(
            $bucket->{'size'}, 1024,
            "Bucket size is 1024 after write() following second open() with $flag_name"
        );
        is(
            $bucket->{'pos'}, 1024,
            "Bucket position is 1024 after second write() following second open() with $flag_name"
        );

        $bucket->close;

        $bucket->open($O_RDONLY);

        is(
            $bucket->{'size'}, 1024,
            "Bucket size is still 1024 after third open() with \$O_RDONLY"
        );
        is(
            $bucket->{'pos'}, 0,
            "Bucket position is 0 after third open() with \$O_RDONLY"
        );

        my $len = $bucket->read( my $buf, 1024 );

        is(
            $len, 1024,
            "read() 1024 bytes after third open() with \$O_RDONLY"
        );
        ok(
            $buf eq 'X' x 1024,
            "read() expected data after third open() with \$O_RDONLY"
        );

        $len = $bucket->read( $buf, 1024 );

        is(
            $len, 0,
            "read() 0 further bytes after third open() with \$O_RDONLY"
        );
        ok(
            $buf eq '',
            "read() expected nothingness after third open() with \$O_RDONLY"
        );

        $bucket->close;
    }
}
