use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

# build fake dist
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ Prereqs => RuntimeRequires => { DoesNotExist => 0 } ],
                [ MetaJSON => ],
                [ 'Test::CheckDeps' => { level => 'suggests', todo_when => '$ENV{_TEST_CHECKDEPS_COND}' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo; 1;",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('t', '00-check-deps.t');
ok( -e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

like(
    $content,
    qr/^BEGIN \{\n^\s*\(\$ENV\{_TEST_CHECKDEPS_COND\}\) && eval "use Test::CheckDeps [\d.]+; 1"\n^\s+or plan skip_all => '[^']+';\n^\}\n^use Test::CheckDeps [\d.]+;/ms,
    'use line is correct',
);

# we can only run the test when todo_when evaluates to true, as we have a
# missing prereq

my $prereqs_tested;
my @test_details;
subtest 'run the generated test' => sub
{
    local $ENV{_TEST_CHECKDEPS_COND} = 1;
    my $wd = pushd $build_dir;

    do $file;
    warn $@ if $@;

    @test_details = sort { $a->{name} cmp $b->{name} } Test::Builder->new->details;
    $prereqs_tested = Test::Builder->new->current_test;
};

# Test::More, Test::CheckDeps, DoesNotExist
is($prereqs_tested, 3, 'correct number of prereqs were tested');

cmp_deeply(
    $test_details[0],
    superhashof({
        ok => 1,
        actual_ok => 0,
        name => re(qr/DoesNotExist/),
        reason => 'these tests are not fatal when $ENV{_TEST_CHECKDEPS_COND}',
    }),
    'a TODO test failed',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
