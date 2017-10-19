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

        _test_with_defaults();
        _test_with_config_bin();
        _test_with_config_bin_scripts();
        _test_with_config_scripts_unchanged();
    }

    done_testing();

    exit 0;
}

{
    # If you run chmod 0644 on a file and read the permissions back with
    # stat what you get back depends on your OS. On Unix you get 0644 back
    # but on Windows you will get something else back. This function creates
    # a hash that maps "permission we set with chmod" to "permission we read
    # back with stat",
    my %p;

    sub _p {
        my ($value) = @_;

        return $p{$value} if exists $p{$value};

        my $tmp_dir = path( tempdir() );
        my $file    = $tmp_dir->child('file.txt');
        $file->spew("hello world\n");

        chmod $value, $file;
        my $perm = ( stat $file )[2] & 07777;

        note( sprintf q{On this system, 'chmod 0%o' results in 0%o}, $value, $perm );
        return $p{$value} = $perm;
    }
}

sub _configure_root {
    my ($root_dir) = @_;

    # Create a git repository in the source
    my $git = Git::Wrapper->new($root_dir);
    $git->init();

    # Create some directories
    $root_dir->child('bin')->mkpath();
    $root_dir->child('scripts')->mkpath();
    $root_dir->child('lib')->mkpath();

    my @files;

    push @files, path($root_dir)->child('bin/a');
    $files[-1]->spew();
    $git->add( $files[-1] );
    chmod 0755, $files[-1];

    push @files, path($root_dir)->child('scripts/b');
    $files[-1]->spew();
    $git->add( $files[-1] );
    chmod 0600, $files[-1];

    push @files, path($root_dir)->child('lib/c.pm');
    $files[-1]->spew();
    $git->add( $files[-1] );
    chmod 0, $files[-1];

    push @files, path($root_dir)->child('d');
    $files[-1]->spew();
    $git->add( $files[-1] );
    chmod 0644, $files[-1];

    is( ( stat $files[0] )[2] & 07777, _p(0755), sprintf q{File '%s' created correctly}, $files[0]->relative($root_dir) );
    is( ( stat $files[1] )[2] & 07777, _p(0600), sprintf q{File '%s' created correctly}, $files[1]->relative($root_dir) );
    is( ( stat $files[2] )[2] & 07777, _p(0),    sprintf q{File '%s' created correctly}, $files[2]->relative($root_dir) );
    is( ( stat $files[3] )[2] & 07777, _p(0644), sprintf q{File '%s' created correctly}, $files[3]->relative($root_dir) );

    return @files;
}

sub _test_with_defaults {

    note('test with default configuration');

    # Create a new "distribution".
    #
    # This copies the content of dist_root to a new directory: $tzil->root
    my $tzil = Builder->from_config(
        { dist_root => tempdir() },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'Git::GatherDir',
                    'Git::FilePermissions',
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    # Configure a Git repository in the source and create our 4 test files
    my @files = _configure_root($root_dir);

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    is( ( stat $files[0] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[0]->relative($root_dir) );
    is( ( stat $files[1] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[1]->relative($root_dir) );
    is( ( stat $files[2] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[2]->relative($root_dir) );
    is( ( stat $files[3] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[3]->relative($root_dir) );

    return;
}

sub _test_with_config_bin {

    note('test with files executable in bin directory');

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
                        'Git::FilePermissions',
                        {
                            perms => '^bin/ 0755',
                        },
                    ],
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    # Configure a Git repository in the source and create our 4 test files
    my @files = _configure_root($root_dir);

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    is( ( stat $files[0] )[2] & 07777, _p(0755), sprintf q{File '%s' adjusted correctly}, $files[0]->relative($root_dir) );
    is( ( stat $files[1] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[1]->relative($root_dir) );
    is( ( stat $files[2] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[2]->relative($root_dir) );
    is( ( stat $files[3] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[3]->relative($root_dir) );

    return;
}

sub _test_with_config_bin_scripts {

    note('test with files executable in bin and script directories');

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
                        'Git::FilePermissions',
                        {
                            perms => [ '^bin/ 0755', '^scripts/ 0755' ],
                        },
                    ],
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    # Configure a Git repository in the source and create our 4 test files
    my @files = _configure_root($root_dir);

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    is( ( stat $files[0] )[2] & 07777, _p(0755), sprintf q{File '%s' adjusted correctly}, $files[0]->relative($root_dir) );
    is( ( stat $files[1] )[2] & 07777, _p(0755), sprintf q{File '%s' adjusted correctly}, $files[1]->relative($root_dir) );
    is( ( stat $files[2] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[2]->relative($root_dir) );
    is( ( stat $files[3] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly}, $files[3]->relative($root_dir) );

    return;
}

sub _test_with_config_scripts_unchanged {

    note('test with files unchanged in scripts directory');

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
                        'Git::FilePermissions',
                        {
                            perms => '^scripts/ -',
                        },
                    ],
                ),
            },
        },
    );

    # Get the directory where the source of the new distributions is
    my $root_dir = path( $tzil->root );

    # Configure a Git repository in the source and create our 4 test files
    my @files = _configure_root($root_dir);

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    is( ( stat $files[0] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly},  $files[0]->relative($root_dir) );
    is( ( stat $files[1] )[2] & 07777, _p(0600), sprintf q{File '%s' correctly unchanged}, $files[1]->relative($root_dir) );
    is( ( stat $files[2] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly},  $files[2]->relative($root_dir) );
    is( ( stat $files[3] )[2] & 07777, _p(0644), sprintf q{File '%s' adjusted correctly},  $files[3]->relative($root_dir) );

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
