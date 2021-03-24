#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use POSIX;
use Fcntl;
use File::Temp;

use_ok('IO::FDSaver');

{
    my $fdsaver = IO::FDSaver->new();

    my $fileno;

    {
        my $fh = File::Temp::tempfile();
        $fileno = fileno $fh;

        my $fh2 = $fdsaver->get_fh( $fileno );

        is(
            fileno($fh2),
            $fileno,
            'get_fh() duplicates',
        );
    }

    my $fh = File::Temp::tempfile();

    isnt( fileno($fh), $fileno, 'FD isn’t reused after GC of original filehandles' );
}

{
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $fd = POSIX::open("$dir/what", Fcntl::O_CREAT | Fcntl::O_WRONLY);

    my $fdsaver = IO::FDSaver->new();
    my $fh = $fdsaver->get_fh( $fd );

    POSIX::close($fd);

    my $fd2 = POSIX::open("$dir/what", Fcntl::O_CREAT | Fcntl::O_WRONLY);

  SKIP: {
        skip "FDs ($fd, $fd2) aren’t the same.", 1 if $fd != $fd2;

        ok( syswrite( $fh, 'hello'), 'can use filehandle even if underlying descriptor is closed & reopened' );
    }
}

done_testing();
