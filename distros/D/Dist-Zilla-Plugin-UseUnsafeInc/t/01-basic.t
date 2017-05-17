use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

plan skip_all => 'these tests require perl 5.025007 or newer' if $] < 5.025007;

$ENV{PERL_USE_UNSAFE_INC} = 'ohhai';    # make sure this is overwritten
$ENV{DZIL_ANY_PERL} = 0;

my %captured_env;
{
    package Dist::Zilla::Plugin::CaptureEnv;
    use Moose;
    with 'Dist::Zilla::Role::AfterBuild';
    sub after_build {
        %captured_env = %ENV;
    }
}

foreach my $input (0, 1)
{
    note "dot_in_INC = $input, perl $], DZIL_ANY_PERL=$ENV{DZIL_ANY_PERL}";
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'UseUnsafeInc' => { dot_in_INC => $input } ],
                    [ CaptureEnv => ],
                    [ FakeRelease => ],
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

    ### BEGIN $tzil->release check
    is(
        exception { $tzil->release },
        undef,
        'release proceeds normally',
    );
    ### END $tzil->release check

    is($captured_env{PERL_USE_UNSAFE_INC}, $input, '$ENV{PERL_USE_UNSAFE_INC} was properly set during build');

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::UseUnsafeInc',
                        config => {
                            'Dist::Zilla::Plugin::UseUnsafeInc' => {
                                dot_in_INC => $input,
                            },
                        },
                        name => 'UseUnsafeInc',
                        version => Dist::Zilla::Plugin::UseUnsafeInc->VERSION,
                    },
                ),
            }),
        }),
        'plugin metadata, including dumped configs',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
