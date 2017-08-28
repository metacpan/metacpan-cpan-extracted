use strict;
use warnings;

use Test::More 0.96;
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
                [ MetaConfig => ],
                [ 'Test::CheckBreaks' => { conflicts_module => 'Moose::Conflicts' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = path($build_dir, 't', 'zzz-check-breaks.t');
ok(-e $file, 'test created');

my $content = $file->slurp;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

# it's important we require using either:
# - an eval'd string rather than via a bareword,
# - or a compound expression,
# so prereq scanners don't grab this module (::Conflicts modules are not
# usually indexed)
like($content, qr/eval \{ \+require $_; $_->check_conflicts \}/, "test checks $_")
    for 'Moose::Conflicts';

cmp_deeply(
    $tzil->distmeta,
    # TODO: replace with Test::Deep::notexists($key)
    code(sub {
        !exists $_[0]->{x_breaks} ? 1 : (0, 'x_breaks exists');
    }),
    'metadata does not get an autovivified x_breaks field',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            test => {
                requires => {
                    'Test::More' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::CheckBreaks',
                    config => superhashof({
                        'Dist::Zilla::Plugin::Test::CheckBreaks' => {
                            conflicts_module => [ 'Moose::Conflicts' ],
                            no_forced_deps => 0,
                        },
                    }),
                    name => 'Test::CheckBreaks',
                    version => Dist::Zilla::Plugin::Test::CheckBreaks->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the test phase; correct dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'saw log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
