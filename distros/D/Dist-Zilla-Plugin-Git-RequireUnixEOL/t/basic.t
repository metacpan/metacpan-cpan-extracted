#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Git::Wrapper;
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

main();

sub main {

  SKIP:
    {
        skip 'Cannot find Git in PATH' if !Git::Wrapper->has_git_in_path();

        _test_with_unix_file();
        _test_with_windows_file();
        _test_with_whitespace_at_end_file();
    }

    done_testing();

    exit 0;
}

sub _test_with_unix_file {
    note('test with a UNIX EOL file');

    # Create a new "distribution".
    #
    # This copies the content of dist_root to a new directory: $tzil->root
    my $tzil = Builder->from_config(
        { dist_root => tempdir() },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'Git::GatherDir',
                    'Git::RequireUnixEOL',
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    my $git = Git::Wrapper->new($root_dir);
    $git->init();

    my $file_name = 'file.txt';
    path($root_dir)->child($file_name)->spew_raw("this\nis\na\nUNIX\nline\nending\ntest\nfile\n");
    $git->add($file_name);

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    return;
}

sub _test_with_windows_file {
    note('test with a Windows EOL file');

    # Create a new "distribution".
    #
    # This copies the content of dist_root to a new directory: $tzil->root
    my $tzil = Builder->from_config(
        { dist_root => tempdir() },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'Git::GatherDir',
                    'Git::RequireUnixEOL',
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    my $git = Git::Wrapper->new($root_dir);
    $git->init();
    my $file_name = 'windows_eol.txt';
    path($root_dir)->child($file_name)->spew_raw("windows\r\neol\r\nfile\r\n");
    $git->add($file_name);

    my $exception = exception { $tzil->build; };
    my @exception = split /\n/xsm, $exception;

    is( @exception, 2, 'Build failed' );
    like( $exception[0], "/ ^ \Q[Git::RequireUnixEOL] ------------------------------------------------------------\E /xsm", '... correct message' );
    like( $exception[1], "/ ^ \Q[Git::RequireUnixEOL] File $file_name uses Windows EOL (found on line 1)\E /xsm",           '... correct message' );

    return;
}

sub _test_with_whitespace_at_end_file {
    note('test with a whitespace at end of line file');

    # Create a new "distribution".
    #
    # This copies the content of dist_root to a new directory: $tzil->root
    my $tzil = Builder->from_config(
        { dist_root => tempdir() },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'Git::GatherDir',
                    'Git::RequireUnixEOL',
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    my $git = Git::Wrapper->new($root_dir);
    $git->init();
    my $file_name = 'whitespace.txt';
    path($root_dir)->child($file_name)->spew_raw("whitespace file\t\n");
    $git->add($file_name);

    my $exception = exception { $tzil->build; };
    my @exception = split /\n/xsm, $exception;

    is( @exception, 2, 'Build failed' );
    like( $exception[0], "/ ^ \Q[Git::RequireUnixEOL] ------------------------------------------------------------\E /xsm", '... correct message' );
    like( $exception[1], "/ ^ \Q[Git::RequireUnixEOL] File $file_name has trailing whitespace on line 1\E /xsm",            '... correct message' );

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
