use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Test::Deep::JSON;

use lib 't/lib';
use Helper;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

# diag uses todo_output if in_todo :/
no warnings 'redefine';
*::diag = sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tb = Test::Builder->new;
    $tb->_print_comment($tb->failure_output, @_);
};

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaJSON => ],
                [ Prereqs => { 'strict' => '0', 'Dist::Zilla' => '5.0' } ],
                [ MakeMaker => ],
                [ DynamicPrereqs => {
                        -raw => [
                            q|$WriteMakefileArgs{PREREQ_PM}{'Dist::Zilla'} = $FallbackPrereqs{'Dist::Zilla'} = '4.300039'|,
                            q|if eval { require CPAN::Meta; CPAN::Meta->VERSION >= '2.132620' };|,
                        ],
                    },
                ],
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
) or diag('got log messages: ', explain $tzil->log_messages);

my $build_dir = path($tzil->tempdir)->child('build');

my $meta_json = $build_dir->child('META.json')->slurp_raw;
cmp_deeply(
    $meta_json,
    json(superhashof({
        dynamic_config => 1,
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => ignore,
                },
            },
            runtime => {
                requires => {
                    'strict' => '0',
                    'Dist::Zilla' => '5.0',
                },
            },
        },
    })),
    'dynamic_config set to 1 in metadata; static prereqs are in place',
)
or diag("found META.json content:\n", $meta_json);


my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');

my $version = Dist::Zilla::Plugin::DynamicPrereqs->VERSION;
isnt(
    index(
        $makefile,
        <<CONTENT),
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs $version
\$WriteMakefileArgs{PREREQ_PM}{'Dist::Zilla'} = \$FallbackPrereqs{'Dist::Zilla'} = '4.300039'
if eval { require CPAN::Meta; CPAN::Meta->VERSION >= '2.132620' };

CONTENT
    -1,
    'code inserted into Makefile.PL',
) or diag("found Makefile.PL content:\n", $makefile);

run_makemaker($tzil);

local $TODO = 'we will need to take greater care when merging with existing prereqs';

my $mymeta_json = $build_dir->child('MYMETA.json')->slurp_raw;
cmp_deeply(
    $mymeta_json,
    json(superhashof({
        dynamic_config => 0,
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => ignore,
                },
            },
            runtime => {
                requires => {
                    'strict' => '0',
                    'Dist::Zilla' => '5.0',
                },
            },
            build => ignore,    # always added by EUMM?
            test => ignore,     # always added by EUMM?
        },
    })),
    'dynamic_config reset to 0 in MYMETA; dynamic prereq does not overshadow greater static prereq',
)
or note 'found MYMETA.json content:', $mymeta_json;

diag('got log messages: ', explain $tzil->log_messages)
    if not Test::Builder->new->is_passing;

done_testing;
