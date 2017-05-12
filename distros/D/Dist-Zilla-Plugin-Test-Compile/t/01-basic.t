use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ ExecDir => ],
                [ MetaConfig => ],
                [ 'Test::Compile' => { bail_out_on_fail => 1, fake_home => 1, } ],
                # we generate a new module after we insert the compile test,
                # to confirm that this module is picked up too
                [ GenerateFile => 'file-from-code' => {
                        filename => 'lib/Baz.pm',
                        is_template => 0,
                        content => [ 'package Baz;', '$VERSION = 0.001;', '1;' ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source lib Bar.pod)) => qq{die 'this .pod file is not valid perl!';\n},
            path(qw(source lib Baz Quz.pm)) => "package Baz::Quz;\n1;\n",
            path(qw(source bin foobar)) => "#!/usr/bin/perl\nprint \"foo\n\";\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t 00-compile.t));
ok(-e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

my @files = (
    path(qw(Foo.pm)),
    path(qw(Baz.pm)),
    path(qw(Baz Quz.pm)),
    path(qw(bin foobar)),
);

like($content, qr/'\Q$_\E'/m, "test checks $_") foreach @files;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            configure => ignore,            # populated by [MakeMaker]
            test => {
                requires => {
                    'Test::More' => '0.94',
                    'File::Spec' => '0',
                    'IPC::Open3' => '0',
                    'IO::Handle' => '0',
                    'File::Temp' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::Compile',
                    config => {
                        'Dist::Zilla::Plugin::Test::Compile' => {
                            module_finder => [ ':InstallModules' ],
                            script_finder => [ eval { Dist::Zilla::Dist::Builder->VERSION('5.038'); 1 }
                                ? ':PerlExecFiles'
                                : ':ExecFiles'
                            ],
                            filename => 't/00-compile.t',
                            fake_home => 1,
                            needs_display => 0,
                            fail_on_warning => 'author',
                            bail_out_on_fail => 1,
                            phase => 'test',
                            skips => [],
                            switch => [],
                        },
                    },
                    name => 'Test::Compile',
                    version => Dist::Zilla::Plugin::Test::Compile->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the test phase; dumped configs are good',
) or diag 'got distmeta: ', explain $tzil->distmeta;

my $num_tests;
subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    $tzil->plugin_named('MakeMaker')->build;

    local $ENV{AUTHOR_TESTING} = 1;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    $num_tests = Test::Builder->new->current_test;
};

is($num_tests, @files + 1, 'correct number of files were tested, plus warnings checked');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
