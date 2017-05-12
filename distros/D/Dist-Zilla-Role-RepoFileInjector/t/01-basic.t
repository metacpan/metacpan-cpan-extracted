use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

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

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'MetaConfig',
                [ '=MyPlugin' => { filename => 'data/my_file.txt' } ],
            ),
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
is($file->slurp_utf8, "hello this is a generated file\n", 'file content is correct');

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
        re(qr{\Q[=MyPlugin] writing out data/my_file.txt to $source_dir\E}),
    ),
    'got debugging messages',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
