use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;
use Test::Fatal;

{
    package MyPlugin;
    use Moose;
    with
        'Dist::Zilla::Role::RepoFileInjector',
        'Dist::Zilla::Role::AfterBuild';
    has filename => ( is => 'ro', isa => 'Str' );

    sub BUILD {
        my $self = shift;
        require Dist::Zilla::File::InMemory;
        $self->add_repo_file(
            Dist::Zilla::File::InMemory->new(
                name => $self->filename,
                content => "hello this is a generated file\n",
            )
        );
    }

    sub after_build { shift->write_repo_files; }
}

# in both cases, file exists in source.
# try with allow_overwrite 0, 1.

subtest 'allow_overwrite = 1' => sub
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'MetaConfig',
                    [ '=MyPlugin' => {
                        filename => 'data/my_file.txt',
                        allow_overwrite => 1,
                      } ],
                ),
                path(qw(source data my_file.txt)) => "This is old content\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $nonfile = path($build_dir, 'data', 'my_file.txt');
    ok(!-e $nonfile, 'file not created in build (' . $build_dir . ')');

    my $source_dir = path($tzil->tempdir)->child('source');
    my $file = path($source_dir, 'data', 'my_file.txt');
    ok(-e $file, 'file created in source (' . $source_dir . ')')
     and
    is($file->slurp_utf8, "hello this is a generated file\n", 'file content is correct; overwritten');

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class => 'MyPlugin',
                    config => {
                        'Dist::Zilla::Role::RepoFileInjector' => {
                            version => Dist::Zilla::Role::RepoFileInjector->VERSION,
                            allow_overwrite => 1,
                            repo_root => '.',
                        },
                    },
                    name => '=MyPlugin',
                    version => undef,
                }),
            }),
        }),
        'config is properly included in metadata',
    )
    or diag 'got distmeta: ', explain $tzil->distmeta;

    cmp_deeply(
        $tzil->log_messages,
        supersetof(
            re(qr{\Q[=MyPlugin] removing pre-existing $source_dir/data/my_file.txt\E}),
            re(qr{\Q[=MyPlugin] writing out data/my_file.txt to $source_dir\E}),
        ),
        'got debugging messages',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
};

subtest 'allow_overwrite = 0' => sub
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'MetaConfig',
                    [ '=MyPlugin' => {
                        filename => 'data/my_file.txt',
                        allow_overwrite => 0,
                      } ],
                ),
                path(qw(source data my_file.txt)) => "This is old content\n",
            },
        },
    );

    my $source_dir = path($tzil->tempdir)->child('source');

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr{\Q[=MyPlugin] $source_dir/data/my_file.txt already exists (allow_overwrite = 0)\E},
        'build dies when the file already exists and allow_overwrite = 0',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
};

done_testing;
