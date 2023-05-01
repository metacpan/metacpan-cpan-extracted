use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use Path::Tiny;
use Test::Deep;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

sub test_build {
    my %test = @_;

    local $ENV{TRIAL} = 1 if $test{trial};

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::BeforeBuild' => { run => [ '"%x" %o%pscript%pbefore_build.pl "%o"' ] } ],
                    [ 'Run::AfterBuild' => {
                        run => [ '"%x" %d%pscript%pafter_build.pl "%s"' ],
                        run_no_trial => [ '"%x" %d%pscript%pno_trial.pl "%s"' ],
                      }
                    ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source script before_build.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path($ARGV[ 0 ], "BEFORE_BUILD.txt")->touch();
SCRIPT
                path(qw(source script after_build.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path($ARGV[ 0 ], 'lib', 'AFTER_BUILD.txt')->spew_raw("after_build");
SCRIPT
                path(qw(source script no_trial.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path($ARGV[0], 'lib', 'NO_TRIAL.txt')->spew_raw(":-P");
SCRIPT
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $source_dir = path($tzil->tempdir)->child('source');
    my $build_dir = path($tzil->tempdir)->child('build');

    my $before_build_result = $source_dir->child('BEFORE_BUILD.txt');
    ok(-f $before_build_result, 'before-build script has been run');

    my $after_build_result = $build_dir->child(qw(lib AFTER_BUILD.txt))->slurp_raw;
    ok($after_build_result eq 'after_build', 'Correct `after_build` result');

    my $no_trial_file = $build_dir->child(qw(lib NO_TRIAL.txt));
    if( $test{trial} ){
        ok( (! -e $no_trial_file), 'is trial - file not written' );

        like $tzil->log_messages->[-1],
            qr{\[Run::AfterBuild\] not executing, because trial: "%x" %d%pscript%pno_trial.pl "%s"},
            'logged skipping of non-trial command';
    }
    else {
        ok( (  -f $no_trial_file), 'non-trial - file present' );
        is $no_trial_file->slurp_raw, ':-P', 'non-trial content';

        my $script = quotemeta $build_dir->child('script','no_trial.pl')->canonpath;   # use OS-specific path separators
        $script =~ s/\\\\/[\\\\\/]/g if  $^O eq 'MSWin32';
        like $tzil->log_messages->[-2],
            qr{\[Run::AfterBuild\] executing: .+ $script .+},
            'logged execution';

        like $tzil->log_messages->[-1],
            qr{\[Run::AfterBuild\] command executed successfully},
            'logged command status';
    }

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%pbefore_build.pl "%o"' ],
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
                                run => [ '"%x" %d%pscript%pafter_build.pl "%s"' ],
                                run_no_trial => [ '"%x" %d%pscript%pno_trial.pl "%s"' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::AfterBuild',
                        version => Dist::Zilla::Plugin::Run::AfterBuild->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs are good',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

test_build();
test_build(trial => 1);

done_testing;
