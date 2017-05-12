use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Dist::Zilla::Plugin::DynamicPrereqs;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

use lib 't/lib';
use Helper;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DynamicPrereqs => 'plugin 1' => { -include_sub => 'can_cc' } ],
                [ DynamicPrereqs => 'plugin 2' => { -include_sub => [qw(can_cc is_smoker)] } ],
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
) or diag 'got log messages: ', explain $tzil->log_messages;

my $build_dir = path($tzil->tempdir)->child('build');

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;

my @definitions = $makefile =~ m/^sub (\w+) \{/mg;
cmp_deeply(
    \@definitions,
    bag(qw(can_cc can_run is_smoker)),
    'subs are only defined once, despite being added by multiple plugins',
) or note "found definitions: @definitions";

run_makemaker($tzil);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
