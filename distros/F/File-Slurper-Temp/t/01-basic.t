#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

# TODO: RT#138255 - some chmod tests fail, don't know why yet

use File::Slurper qw(
                        read_text
                );
use File::Slurper::Temp qw(
                              write_text
                              write_binary
                              write_text_to_tempfile
                              write_binary_to_tempfile
                              modify_text
                              modify_binary
                      );
use File::Temp qw(tempdir);

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
note "Temporary directory for testing: $tempdir (not cleaned up)"
    if $ENV{DEBUG};
mkdir "$tempdir/dir1";

subtest "write_text" => sub {
    subtest "basics" => sub {
        lives_ok { write_text "$tempdir/1", "foo" };
        is(read_text("$tempdir/1"), "foo");

        # modify an existing file with permission 0644
        my @st;

        chmod 0660, "$tempdir/1" or die;
        write_text "$tempdir/1", "foo2";
        @st = stat "$tempdir/1" or die;
        is($st[2] & 0777, 0660);

        chmod 0644, "$tempdir/1" or die;
        write_text "$tempdir/1", "foo3";
        @st = stat "$tempdir/1" or die;
        is($st[2] & 0777, 0644);
    };

    # TODO: test setting $FILE_TEMP_TEMPLATE

    subtest "Setting \$FILE_TEMP_DIR" => sub {
        lives_ok {
            local $File::Slurper::Temp::FILE_TEMP_DIR = "$tempdir/dir1";
            write_text "$tempdir/2", "bar";
            is(read_text("$tempdir/2"), "bar");
        };
        dies_ok {
            local $File::Slurper::Temp::FILE_TEMP_DIR = "$tempdir/non-existent";
            write_text "$tempdir/3", "baz";
        };
    };

    subtest "Setting \$FILE_TEMP_PERMS" => sub {
        lives_ok {
            my @st;

            local $File::Slurper::Temp::FILE_TEMP_PERMS = 0600;
            write_text "$tempdir/1", "foo4";
            is(read_text("$tempdir/1"), "foo4");
            @st = stat "$tempdir/1" or die;
            is($st[2] & 0777, 0600);

            $File::Slurper::Temp::FILE_TEMP_PERMS = 0604;
            write_text "$tempdir/1", "foo5";
            is(read_text("$tempdir/1"), "foo5");
            @st = stat "$tempdir/1" or die;
            is($st[2] & 0777, 0604);
        };
    };
};

# XXX write_binary

subtest "write_text_to_tempfile" => sub {
    subtest "basics" => sub {
        my $path;
        lives_ok { $path = write_text_to_tempfile("foo") };
        ok($path);
    };
};

# XXX write_binary_to_tempfile

subtest "modify_text" => sub {
    dies_ok { modify_text("$tempdir/not-existent", sub { 1 }) } "file does not exist -> dies";
    dies_ok { modify_text("$tempdir/1", sub { 0 }) } "code does not return true -> dies";
    modify_text("$tempdir/1", sub { s/foo/FOO/ });
    is(read_text("$tempdir/1"), "FOO5");
};

# XXX modify_binary

done_testing;
