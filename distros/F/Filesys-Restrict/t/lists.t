#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use Config;

use File::Temp ();

use Filesys::Restrict;

my $tempdir = File::Temp::tempdir();

my $good_dir = "$tempdir/good";

mkdir $good_dir;

{
    my $check = Filesys::Restrict::create( sub {
        my $path = $_[1];

        return $path =~ m<\A\Q$good_dir\E/>;
    } );

    {
        open my $fh, '>', "$good_dir/foo";
    }

    lives_ok(
        sub { unlink "$good_dir/foo" },
        'unlink w/ one approved arg',
    );

    ok( !(-e "$good_dir/foo"), 'unlink was effective' );

    lives_ok(
        sub { unlink "$good_dir/foo", "$good_dir/bar" },
        'unlink w/ two approved args',
    );

    throws_ok(
        sub { unlink "$good_dir/foo", "$good_dir/bar", "$tempdir/baz" },
        'Filesys::Restrict::X::Forbidden',
        'unlink w/ two approved args and one forbidden',
    );

    #----------------------------------------------------------------------

    {
        open my $fh, '>', "$good_dir/foo";
    }

    lives_ok(
        sub { chmod 0444, "$good_dir/foo" or warn $! },
        'chmod w/ one approved path',
    );

    is(
        (stat "$good_dir/foo")[2] & 0777,
        0444,
        'chmod() was effective',
    );

    lives_ok(
        sub { chmod 0444, "$good_dir/foo", "$good_dir/bar" },
        'chmod w/ two approved args',
    );

    throws_ok(
        sub { chmod 0444, "$good_dir/foo", "$good_dir/bar", "$tempdir/baz" },
        'Filesys::Restrict::X::Forbidden',
        'chmod w/ two approved args and one forbidden',
    );

    if ($Config{'d_fchmod'}) {
        lives_ok(
            sub { chmod 0777, \*STDIN },
            'chmod w/ filehandle',
        );
    }

    #----------------------------------------------------------------------

    lives_ok(
        sub { chown 0, 0, "$good_dir/foo" },
        'chown w/ one approved path',
    );

    lives_ok(
        sub { chown 0, 0, "$good_dir/foo", "$good_dir/bar" },
        'chown w/ two approved args',
    );

    throws_ok(
        sub { chown 0, 0, "$good_dir/foo", "$good_dir/bar", "$tempdir/baz" },
        'Filesys::Restrict::X::Forbidden',
        'chown w/ two approved args and one forbidden',
    );

    if ($Config{'d_fchown'}) {
        lives_ok(
            sub { chown 0, 0, \*STDIN },
            'chown w/ filehandle',
        );
    }

    #----------------------------------------------------------------------

    my $now = time;

    lives_ok(
        sub { utime $now, $now, "$good_dir/foo" },
        'utime w/ one approved path',
    );

    lives_ok(
        sub { utime $now, $now, "$good_dir/foo", "$good_dir/bar" },
        'utime w/ two approved args',
    );

    throws_ok(
        sub { utime $now, $now, "$good_dir/foo", "$good_dir/bar", "$tempdir/baz" },
        'Filesys::Restrict::X::Forbidden',
        'utime w/ two approved args and one forbidden',
    );

    if ($Config{'d_futimes'}) {
        lives_ok(
            sub { utime $now, $now, \*STDIN },
            'utime w/ filehandle',
        );
    }
}

done_testing;
