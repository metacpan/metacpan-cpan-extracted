use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

my $gathered_files;
{
    package inc::MyGatherer;
    use Moose;
    with 'Dist::Zilla::Role::FileGatherer';

    sub gather_files {
        my $self = shift;
        $gathered_files = $self->zilla->files;
    }
}

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ InstallGuide => ],
                [ '=inc::MyGatherer' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('INSTALL');
ok(-e $file, 'INSTALL created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated file');

like($content, qr/Makefile.PL/m, 'INSTALL mentions Makefile.PL');
unlike($content, qr/Build.PL/m, 'INSTALL does not mention Build.PL');

ok(
    scalar(grep { $_->name eq 'INSTALL' } @$gathered_files),
    'file was created at FileGathering time',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
