use strict;
use warnings;
use Test::More 0.96;

# Adapted from Dist::Zilla t/plugins/prereqs.t by Ricardo Signes

use lib 't/lib';

use JSON 2;
use Test::DZil;

subtest 'all phases' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    #<<< No perltidy
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs   => => { A => 1, Z => 1 } ],
                    [ Prereqs   => RuntimeRequires   => { A => 2, B => 1 } ],
                    [ Prereqs   => BuildRequires     => { B => 2, C => 1 } ],
                    [ Prereqs   => DevelopSuggests   => { C => 2, D => 1 } ],
                    [ Prereqs   => TestRecommends    => { D => 2, E => 1 } ],
                    [ Prereqs   => ConfigureRequires => { E => 2, F => 1 } ],
                    [
                        RemovePhasedPrereqs => {
                            remove_runtime      => [qw(B Z)],
                            remove_build        => [qw(C)],
                            remove_develop      => [qw(D)],
                            remove_test         => [qw(E)],
                            remove_configure    => [qw(F)],
                        }
                    ],
                    ##>>>
                ),
            },
        },
    );

    $tzil->build;

    my $json = $tzil->slurp_file('build/META.json');

    my $meta = JSON->new->decode($json);

    is_deeply(
        $meta->{prereqs},
        {
            runtime     => { requires   => { A => 2 } },
            build       => { requires   => { B => 2 } },
            develop     => { suggests   => { C => 2 } },
            test        => { recommends => { D => 2 } },
            configure   => { requires   => { E => 2 } },
        },
        "prereqs merged and pruned",
    );
};

subtest 'only one phase' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    #<<< No perltidy
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs   => => { A => 1, Z => 1 } ],
                    [
                        RemovePhasedPrereqs => {
                            remove_runtime      => [qw(Z)],
                        }
                    ],
                    ##>>>
                ),
            },
        },
    );

    $tzil->build;

    my $json = $tzil->slurp_file('build/META.json');

    my $meta = JSON->new->decode($json);

    is_deeply(
        $meta->{prereqs},
        {
            runtime     => { requires   => { A => 1 } },
        },
        "prereqs merged and pruned",
    );
};

done_testing;

# vim: ts=4 sts=4 sw=4 et:
