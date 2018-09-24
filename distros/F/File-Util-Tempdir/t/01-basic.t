#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Perl::osnames;
use File::Temp qw(tempdir);
use File::Util::Tempdir qw(get_tempdir get_user_tempdir);

subtest get_tempdir => sub {
    my $dir;
    lives_ok { $dir = get_tempdir() };
    diag "result of get_tempdir(): ", $dir;
};

subtest get_user_tempdir => sub {
    my $dir;
    lives_ok { $dir = get_user_tempdir() };
    diag "result of get_user_tempdir(): ", $dir;

    subtest "unix tests" => sub {
        plan skip_all => "Unix only" unless Perl::osnames::is_unix();

        my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
        diag "tempdir=$tempdir" if $ENV{DEBUG};

        local $ENV{XDG_RUNTIME_DIR};
        local $ENV{TMPDIR};
        local $ENV{TEMPDIR};
        local $ENV{TMP};
        local $ENV{TEMP};

        $ENV{XDG_RUNTIME_DIR} = $tempdir;
        is(get_user_tempdir(), $tempdir, "uses XDG_RUNTIME_DIR");

        subtest "root tempdir tests" => sub {
            plan skip_all => "not root" if $>;

            mkdir "$tempdir/sub0", 0700 or die;
            chmod 0700, "$tempdir/sub0" or die;
            chown 1000, 0, "$tempdir/sub0" or die;
            $ENV{XDG_RUNTIME_DIR} = "$tempdir/sub0";
            is(get_user_tempdir(), "$tempdir/sub0/$>",
               "rejects different-owner tempdir");
        };

        mkdir "$tempdir/sub1", 0757 or die;
        chmod 0757, "$tempdir/sub1" or die;
        $ENV{XDG_RUNTIME_DIR} = "$tempdir/sub1";
        is(get_user_tempdir(), "$tempdir/sub1/$>",
           "rejects world-writable tempdir");

        mkdir "$tempdir/sub2", 0775 or die;
        chmod 0775, "$tempdir/sub2" or die;
        $ENV{XDG_RUNTIME_DIR} = "$tempdir/sub2";
        is(get_user_tempdir(), "$tempdir/sub2/$>",
           "rejects group-writable tempdir");

        undef $ENV{XDG_RUNTIME_DIR};
        $ENV{TMPDIR} = $tempdir;
        is(get_user_tempdir(), $tempdir, "uses TMPDIR");
        # XXX checks uses TEMPDIR TMP TEMP

        mkdir "$tempdir/sub3", 0777 or die;
        chmod 0777, "$tempdir/sub3" or die;
        $ENV{TMPDIR} = "$tempdir/sub3";
        mkdir "$tempdir/sub3/$>", 0757 or die;
        chmod 0757, "$tempdir/sub3/$>" or die;
        is(get_user_tempdir(), "$tempdir/sub3/$>.1",
           "rejects world-writable subdir");
        chmod 0775, "$tempdir/sub3/$>.1" or die;
        is(get_user_tempdir(), "$tempdir/sub3/$>.2",
           "rejects group-writable subdir");
        subtest "root subdir tests" => sub {
            plan skip_all => "not root" if $>;

            $ENV{TMPDIR} = "$tempdir/sub0";
            chown 1000, 0, "$tempdir/sub0/$>" or die;
            is(get_user_tempdir(), "$tempdir/sub0/$>.1",
               "rejects different-owner subdir");
        };

    };
};

done_testing;
