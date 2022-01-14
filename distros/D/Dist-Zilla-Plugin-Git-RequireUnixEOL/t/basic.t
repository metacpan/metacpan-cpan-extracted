#!perl

use 5.006;
use strict;
use warnings;

use Git::Background 0.003;
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

main();

sub main {

  SKIP:
    {
        skip 'Cannot find Git in PATH', 1 if !defined Git::Background->version;

        _test_with_unix_file();
        _test_with_windows_file();
        _test_with_whitespace_at_end_file();
        _test_with_ignored_whitespace_at_end_file();
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

    my $git = Git::Background->new($root_dir);
    $git->run('init')->get;

    my $file_name = 'file.txt';
    path($root_dir)->child($file_name)->spew_raw("this\nis\na\nUNIX\nline\nending\ntest\nfile\n");
    $git->run( 'add', $file_name )->get;

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

    my $git = Git::Background->new($root_dir);
    $git->run('init')->get;
    my $file_name = 'windows_eol.txt';
    path($root_dir)->child($file_name)->spew_raw("windows\r\neol\r\nfile\r\n");
    $git->run( 'add', $file_name )->get;

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

    my $git = Git::Background->new($root_dir);
    $git->run('init')->get;
    my $file_name = 'whitespace.txt';
    path($root_dir)->child($file_name)->spew_raw("whitespace file\t\n");
    $git->run( 'add', $file_name )->get;

    my $exception = exception { $tzil->build; };
    my @exception = split /\n/xsm, $exception;

    is( @exception, 2, 'Build failed' );
    like( $exception[0], "/ ^ \Q[Git::RequireUnixEOL] ------------------------------------------------------------\E /xsm", '... correct message' );
    like( $exception[1], "/ ^ \Q[Git::RequireUnixEOL] File $file_name has trailing whitespace on line 1\E /xsm",            '... correct message' );

    return;
}

sub _test_with_ignored_whitespace_at_end_file {
    note('test with an ignored file with whitespace at end of line');

    # Create a new "distribution".
    #
    # This copies the content of dist_root to a new directory: $tzil->root
    my $tzil = Builder->from_config(
        { dist_root => tempdir() },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'Git::GatherDir',
                    [
                        'Git::RequireUnixEOL',
                        {
                            ignore => 'whitespace.txt',
                        },
                    ],
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    my $git = Git::Background->new($root_dir);
    $git->run('init')->get;

    my $file_name = 'whitespace.txt';
    path($root_dir)->child($file_name)->spew_raw("whitespace file\t\n");
    $git->run( 'add', $file_name )->get;

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
