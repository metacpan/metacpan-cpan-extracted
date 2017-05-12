use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Term::ANSIColor 2.01 'colorstrip';
use Dist::Zilla::Plugin::DynamicPrereqs;

use Test::Needs { 'ExtUtils::HasCompiler' => '0.014' };

# this time, we use our real sub definitions
use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

use lib 't/lib';
use Helper;

my @subs = sort
    grep { !/^\./ }
    map { $_->basename }
    path(File::ShareDir::module_dir('Dist::Zilla::Plugin::DynamicPrereqs'), 'include_subs')->children;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DynamicPrereqs => { -include_sub => \@subs } ],
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

cmp_deeply(
    [ map { colorstrip($_) } @{ $tzil->log_messages } ],
    supersetof(
        map { re(qr/^\Q[DynamicPrereqs] Use $_ with great care! Please consult the documentation!\E$/) } qw(can_cc can_run can_xs),
    ),
    'warning printed for unstable sub implementations',
) or diag 'got log messages: ', explain $tzil->log_messages;

my $build_dir = path($tzil->tempdir)->child('build');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        dynamic_config => 1,
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => ignore,
                    'Config' => '0',
                    'File::Spec' => '0',
                    'Text::ParseWords' => '0',
                    'Module::Metadata' => '0',
                    'CPAN::Meta::Requirements' => '2.120620',
                    'DynaLoader' => '0',
                },
            },
            develop => {
                requires => {
                    'ExtUtils::HasCompiler' => '0.014',
                },
            },
        },
    }),
    'added prereqs used by included subs',
)
or diag 'found metadata: ', explain $tzil->distmeta;

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');
unlike($makefile, qr/\t/m, 'no tabs in modified file');

isnt(
    index($makefile, "sub $_ {"),
    -1,
    "Makefile.PL contains definition for $_()",
) foreach @subs;

run_makemaker($tzil);

{
    no strict 'refs';
    cmp_deeply(
        \%{'main::MyTestMakeMaker::'},
        superhashof({
            map {; $_ => *{"MyTestMakeMaker::$_"} } @subs
        }),
        'Makefile.PL defined all required subroutines',
    ) or diag 'Makefile.PL defined symbols: ', explain \%{'main::MyTestMakeMaker::'};
}

my $inc_dir = $build_dir->child('inc');
my @inc_files;
$inc_dir->visit(
    sub { push @inc_files, $_->relative($build_dir)->stringify if -f },
    { recurse => 1 },
);

cmp_deeply(
    \@inc_files,
    [ $inc_dir->child(qw(ExtUtils HasCompiler.pm))->relative($build_dir)->stringify ],
    'only the one included module is found, with no other dependencies pulled in',
)
or diag 'found files in inc: ', explain \@inc_files;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
