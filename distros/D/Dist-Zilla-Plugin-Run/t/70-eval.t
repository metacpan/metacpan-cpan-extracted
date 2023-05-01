use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use TestHelper;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

my $command = 'Path::Tiny::path(\'%o\', \'eval_out.txt\')->append_raw(';
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ FakeRelease => ],
                [ 'Run::BeforeBuild' => {
                    eval => [ $command . '\'before_build for [\' . $_[0]->plugin_name . \'], %s %n %v .%d.%a. %x\' . qq{\\n});' ] } ],
                [ 'Run::AfterBuild' => {
                    eval => [ $command . '\'after_build for [\' . $_[0]->plugin_name . \'], %n %v %d %s %s %v .%a. %x\' . qq{\\n});' ] } ],
                [ 'Run::BeforeArchive' => {
                    eval => [ $command . '\'before_archive for [\' . $_[0]->plugin_name . \'], %n %v %d .%a. %x\' . qq{\\n});' ] } ],
                [ 'Run::BeforeRelease' => {
                    eval => [ $command . '\'before_release for [\' . $_[0]->plugin_name . \'], %n -d %d %s -v %v .%a. %x\' . qq{\\n});' ] } ],
                [ 'Run::Release' => {
                    eval => [ $command . '\'release for [\' . $_[0]->plugin_name . \'], %s %n %v %d/a %d/b %a %x\' . qq{\\n});' ] } ],
                [ 'Run::AfterRelease' => {
                    eval => [ $command . '\'after_release for [\' . $_[0]->plugin_name . \'], %d %v %s %s %n %a %x\' . qq{\\n});' ] } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $source_dir = path($tzil->tempdir)->child('source');

my %f = (
    a => 'DZT-Sample-0.001.tar.gz',
    n => 'DZT-Sample',
    o => $source_dir,
    d => $build_dir,
    v => '0.001',
    x => do { my $path = Dist::Zilla::Plugin::Run::Role::Runner->current_perl_path; $path =~ s{\\}{/}g; $path },
);

# test constant conversions as well as positional %s for backward compatibility
my $expected = <<OUTPUT;
before_build for [Run::BeforeBuild], $f{v} $f{n} $f{v} ... $f{x}
after_build for [Run::AfterBuild], $f{n} $f{v} $f{d} $f{d} $f{v} $f{v} .. $f{x}
before_archive for [Run::BeforeArchive], $f{n} $f{v} $f{d} .. $f{x}
before_release for [Run::BeforeRelease], $f{n} -d $f{d} $f{a} -v $f{v} .$f{a}. $f{x}
release for [Run::Release], $f{a} $f{n} $f{v} $f{d}/a $f{d}/b $f{a} $f{x}
after_release for [Run::AfterRelease], $f{d} $f{v} $f{a} $f{v} $f{n} $f{a} $f{x}
OUTPUT

is_path(
    $source_dir->child('eval_out.txt')->slurp_raw,
    $expected,
    'all phases evaluate their code directly',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'before_build for [\' . $_[0]->plugin_name . \'], %s %n %v .%d.%a. %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::BeforeBuild',
                    version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Run::AfterBuild',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'after_build for [\' . $_[0]->plugin_name . \'], %n %v %d %s %s %v .%a. %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::AfterBuild',
                    version => Dist::Zilla::Plugin::Run::AfterBuild->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Run::BeforeArchive',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'before_archive for [\' . $_[0]->plugin_name . \'], %n %v %d .%a. %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::BeforeArchive',
                    version => Dist::Zilla::Plugin::Run::BeforeArchive->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Run::BeforeRelease',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'before_release for [\' . $_[0]->plugin_name . \'], %n -d %d %s -v %v .%a. %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::BeforeRelease',
                    version => Dist::Zilla::Plugin::Run::BeforeRelease->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Run::Release',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'release for [\' . $_[0]->plugin_name . \'], %s %n %v %d/a %d/b %a %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::Release',
                    version => Dist::Zilla::Plugin::Run::Release->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Run::AfterRelease',
                    config => {
                        'Dist::Zilla::Plugin::Run::Role::Runner' => {
                            eval => [ $command . '\'after_release for [\' . $_[0]->plugin_name . \'], %d %v %s %s %n %a %x\' . qq{\\n});' ],
                            fatal_errors => 1,
                            quiet => 0,
                            version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                        },
                    },
                    name => 'Run::AfterRelease',
                    version => Dist::Zilla::Plugin::Run::AfterRelease->VERSION,
                },
            ),
        }),
    }),
    'dumped configs are good',
) or diag 'got distmeta: ', explain $tzil->distmeta;

cmp_deeply(
    [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
    [
        '[Run::BeforeBuild] attempting to use %d in before_build',
        '[Run::BeforeBuild] attempting to use %a in a non-Release plugin',
        re(qr/^\Q[Run::BeforeBuild] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('before_build \E/),

        '[Run::AfterBuild] attempting to use %a in a non-Release plugin',
        re(qr/^\Q[Run::AfterBuild] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('after_build \E/),

        '[Run::BeforeArchive] attempting to use %a in a non-Release plugin',
        re(qr/^\Q[Run::BeforeArchive] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('before_archive \E/),

        re(qr/^\Q[Run::BeforeRelease] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('before_release \E/),
        re(qr/^\Q[Run::Release] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('release \E/),
        re(qr/^\Q[Run::AfterRelease] evaluating: Path::Tiny::path('$source_dir', 'eval_out.txt')->append_raw('after_release \E/),
    ],
    'got diagnostics when code is evaluated',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
