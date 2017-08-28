use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

foreach my $input (0, 'off', 1, 'on')
{
    note "mode = $input";
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MakeMaker => ],
                    [ MetaJSON => ],
                    [ 'StaticInstall' => { mode => $input } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    # intentionally not setting logging to verbose mode

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my $mode = ($input eq 'on' || $input eq 1) ? 'on'
             : ($input eq 'off' || $input eq 0) ? 'off'
             : die "unrecognized input '$input'";

    my $flag = ($input eq 'on' || $input eq 1) ? 1
             : ($input eq 'off' || $input eq 0) ? 0
             : die "unrecognized input '$input'";

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            # TODO: replace with Test::Deep::notexists($key)
            prereqs => code(sub {
                !exists $_[0]->{build} ? 1 : (0, 'build exists');
            }),
            x_static_install => $flag,
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::StaticInstall',
                        config => {
                            'Dist::Zilla::Plugin::StaticInstall' => {
                                mode => $mode,
                                dry_run => 0,
                            },
                        },
                        name => 'StaticInstall',
                        version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                    },
                ),
            }),
        }),
        "given input of $input, passed mode = $mode and got x_static_install = $flag",
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    cmp_deeply(
        $tzil->log_messages,
        supersetof("[StaticInstall] setting x_static_install to $flag"),
        'logged the flag value',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
