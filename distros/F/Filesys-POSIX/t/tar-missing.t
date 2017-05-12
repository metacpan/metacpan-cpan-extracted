# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX                ();
use Filesys::POSIX::Mem           ();
use Filesys::POSIX::Userland::Tar ();
use Filesys::POSIX::Extensions    ();

use File::Temp ();

use Test::More ( 'tests' => 3 );
use Test::Exception;
use Test::Filesys::POSIX::Error;

package Test::Filesys::POSIX::Data;

sub generate {
    my ($class) = @_;

    my $fs = Filesys::POSIX->new(
        Filesys::POSIX::Mem->new,
        'noatime' => 1
    );

    my ( $tmpfh, $tmpfile ) = File::Temp::tempfile();
    print {$tmpfh} "non-empty file contents\n";
    close $tmpfh;

    $fs->map( $tmpfile => 'foo' );

    open( my $fh, '>', '/dev/null' ) or die("Unable to open /dev/null for writing: $!");

    return bless {
        'fs'      => $fs,
        'fh'      => $fh,
        'handle'  => Filesys::POSIX::IO::Handle->new($fh),
        'tmpfile' => $tmpfile
    }, $class;
}

sub test {
    my ( $self, @items ) = @_;

    return $self->{'fs'}->tar( $self->{'handle'}, @items );
}

sub DESTROY {
    my ($self) = @_;

    close $self->{'fh'};
    unlink $self->{'tmpfile'} if -f $self->{'tmpfile'};

    return;
}

package main;

{
    my $success = 0;

    my $callback = sub {
        my ($path) = @_;

        $success = 1 if $path =~ /foo/;

        return;
    };

    my $data = Test::Filesys::POSIX::Data->generate;

    unlink $data->{'tmpfile'};

    lives_ok {
        $data->test(
            { 'ignore_missing' => $callback },
            '.'
        );
    }
    '$fs->tar() does not die when passed a callback via "ignore_missing"';

    ok( $success, '$fs->tar() executes "ignore_missing" callback on missing file' );
}

{
    my $data = Test::Filesys::POSIX::Data->generate;

    unlink $data->{'tmpfile'};

    throws_errno_ok {
        $data->test('.');
    }
    &Errno::ENOENT, '$fs->tar() dies when encountering missing file';
}
