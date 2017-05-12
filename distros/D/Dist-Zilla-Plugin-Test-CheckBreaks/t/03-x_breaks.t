use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;
use CPAN::Meta::Check;

use lib 't/lib';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Test::CheckBreaks' => { no_forced_deps => 0 } ],
                [ '=Breaks' => {
                    'ClassA' => '>= 1.0',   # fails; stored as 'version'
                    'ClassB' => '<= 20.0',  # fails
                    'ClassC' => '== 1.0',   # fails
                    'ClassD' => '!= 1.0',   # passes
                    CPAN::Meta::Check->VERSION >= '0.014' ? (
                        'ClassE' => '<= 1.0',   # fails
                        'ClassF' => '!= 1.0',   # fails
                    ) : (),
                  }
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            # we will add perl5 lib to @INC
            path(qw(perl5 lib ClassA.pm)) => "package ClassA;\n\$ClassA::VERSION = '1.0';\n1;",
            path(qw(perl5 lib ClassB.pm)) => "package ClassB;\n\$ClassB::VERSION = '1.0';\n1;",
            path(qw(perl5 lib ClassC.pm)) => "package ClassC;\n\$ClassC::VERSION = '1.0';\n1;",
            path(qw(perl5 lib ClassD.pm)) => "package ClassD;\n\$ClassD::VERSION = '1.0';\n1;",
            path(qw(perl5 lib ClassE.pm)) => "package ClassE;\n\n1;",  # no $VERSION
            path(qw(perl5 lib ClassF.pm)) => "package ClassF;\n\n1;",  # no $VERSION
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

unlike($content, qr/$_/, "test does not do anything with $_")
    for 'Foo::Conflicts';

my @expected_break_specs = (
    '"ClassA".*"1.0"',
    '"ClassB".*"<= 20.0"',
    '"ClassC".*"== 1.0"',
    '"ClassD".*"!= 1.0"',
    CPAN::Meta::Check->VERSION >= '0.014' ? (
        '"ClassE".*"<= 1.0"',
        '"ClassF".*"!= 1.0"',
    ) : (),
);

like($content, qr/$_/, 'test checks the right version range') foreach @expected_break_specs;

like($content, qr/^use CPAN::Meta::Requirements;/m, 'test uses CPAN::Meta::Requirements');
my $cmc_prereq = Dist::Zilla::Plugin::Test::CheckBreaks->_cmc_prereq;
like($content, qr/^use CPAN::Meta::Check $cmc_prereq;/m, "test uses CPAN::Meta::Check $cmc_prereq");

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            test => {
                requires => {
                    'Test::More' => '0',
                    'CPAN::Meta::Requirements' => '0',
                    'CPAN::Meta::Check' => $cmc_prereq,
                },
            },
        },
        x_breaks => {
            'ClassA' => '1.0',
            'ClassB' => '<= 20.0',
            'ClassC' => '== 1.0',
            'ClassD' => '!= 1.0',
            CPAN::Meta::Check->VERSION >= '0.014' ? (
                'ClassE' => '<= 1.0',
                'ClassF' => '!= 1.0',
            ) : (),
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::CheckBreaks',
                    config => superhashof({
                        'Dist::Zilla::Plugin::Test::CheckBreaks' => {
                            conflicts_module => [],
                            no_forced_deps => 0,
                        },
                    }),
                    name => 'Test::CheckBreaks',
                    version => Dist::Zilla::Plugin::Test::CheckBreaks->VERSION,
                },
            ),
        }),
    }),
    'correct test prereqs are injected; correct dumped configs',
);

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    # make diag act like note
    my $tb = Test::Builder->new;
    my $saved_stderr = $tb->failure_output;
    $tb->failure_output($tb->output);

    local @INC = (path($tzil->tempdir, qw(perl5 lib))->stringify, @INC);

    do $file;
    die $@ if $@;

    $tb->failure_output($saved_stderr);

    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

# we define a global $result in the test, which we can now use to extract the values of the test
my $breaks_result = eval '$main::result';

my $is_defined = code(sub { defined($_[0]) || (0, 'value not defined') });
cmp_deeply(
    $breaks_result,
    {
        'ClassA' => $is_defined,
        'ClassB' => $is_defined,
        'ClassC' => $is_defined,
        'ClassD' => undef,
        CPAN::Meta::Check->VERSION >= '0.014' ? (
            'ClassE' => $is_defined,
            'ClassF' => $is_defined,
        ) : (),
    },
    'breakages checked, with the correct results achieved',
);

diag 'saw log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
