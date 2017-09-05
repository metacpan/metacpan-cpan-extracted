#!perl

use strict;
use warnings;

use Test::DZil;
use Test::Fatal;
use Test::More;

use Dist::Zilla::Plugin::AutoPrereqs::Perl::Critic;
use Perl::Critic;

my $perl_critic_version = Perl::Critic->VERSION();

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'AutoPrereqs::Perl::Critic',
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'develop' => {
            'requires' => {
                'Perl::Critic' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, 'without a single active policy only Perl::Critic is returned as dependency' );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',
                        {
                            phase => 'test',
                        }
                    ],
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'test' => {
            'requires' => {
                'Perl::Critic' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{'phase' argument works} );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',

                        {
                            phase => 'test',
                            type  => 'recommends',
                        }
                    ],
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'test' => {
            'recommends' => {
                'Perl::Critic' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{'phase' and 'recommends' arguments work} );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ2' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',

                        {
                            critic_config => 'perl_critic_config.txt',
                            phase         => 'test',
                            type          => 'recommends',
                        }
                    ],
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'test' => {
            'recommends' => {
                'Perl::Critic' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{'critic_config', 'phase' and 'recommends' arguments work} );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ3' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',

                        {
                            critic_config => 'perl_critic_config.txt',
                            phase         => 'test',
                            type          => 'recommends',
                        }
                    ],
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'test' => {
            'recommends' => {
                'Perl::Critic' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, 'core policy is not added to prereq' );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ3' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',

                        {
                            critic_config        => 'perl_critic_config.txt',
                            phase                => 'test',
                            type                 => 'recommends',
                            remove_core_policies => 0,
                        }
                    ],
                ),
            },
        }
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $expected = {
        'test' => {
            'recommends' => {
                'Perl::Critic'                                                    => $perl_critic_version,
                'Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{'remove_core_policies' argument works} );
}

done_testing();

# vim: ts=4 sts=4 sw=4 et: syntax=perl
