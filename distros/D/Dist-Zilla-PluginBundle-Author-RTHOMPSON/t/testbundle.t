#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Moose::Autobox;

require Dist::Zilla::PluginBundle::Author::RTHOMPSON;

my %tzil = (
    normal => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                    }
                ])
            },
        }
    ),
    staticversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                        version => '1.5',
                    }
                ])
            },
        }
    ),
    disableversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Specify version here
                    version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                        version => 'none',
                    }
                ])
            },
        }
    ),
    emptyversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Specify version here
                    version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                        version => '',
                    }
                ])
            },
        }
    ),
    removeplugin => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                        '-remove' => [ 'GithubMeta', 'Git::Push' ],
                    }
                ])
            },
        }
    ),
    # This config just attempts to explicitly pass every option, to
    # make sure the bundle will accept them all.
    manyoptions => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@Author::RTHOMPSON', {
                        release => 'fake',
                        'version' => 'auto',
                        'version_major' => 1,
                        '-remove' => [ 'GithubMeta', 'Git::Push' ],
                        copy_file => [ 'README' ],
                        move_file => [ 'does_not_exist' ],
                        synopsis_is_perl_code => 'false',
                        archive => 'false',
                        archive_directory => "releases",
                        vcs => 'git',
                        git_remote => 'origin',
                        git_branch => 'master',
                        git_remote_branch => 'master',
                        no_check_remote => 'false',
                        no_push => 'false',
                        allow_dirty => [ qw( dist.ini Changes and README.pod ) ],
                        'ExecDir.dir' => 'bin',
                    }
                ])
            },
        }
    ),
);

plan tests => 2 * keys %tzil;

for my $name (keys %tzil) {
    my $tzil = $tzil{$name};
    lives_ok { $tzil->build; } "$name dist builds successfully";
    my $readme_content = $tzil->slurp_file('build/README');
    like($readme_content, qr/\S/, "$name dist has a non-empty README file");
}

done_testing();
