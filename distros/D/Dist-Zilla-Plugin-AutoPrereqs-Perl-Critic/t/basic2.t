#!perl

use strict;
use warnings;

use Test::DZil;
use Test::Fatal;
use Test::More;

use lib 'corpus/dist/DZ4/lib/';

use Dist::Zilla::Plugin::AutoPrereqs::Perl::Critic;
use Perl::Critic;

my $perl_critic_version = Perl::Critic->VERSION();

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ4' },
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
                'Perl::Critic'                   => $perl_critic_version,
                'Perl::Critic::Policy::SKIRMESS' => '0.000001',
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{non-core plugin is added to prereq} );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ4' },
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
                'Perl::Critic::Policy::SKIRMESS'                                  => '0.000001',
                'Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish' => $perl_critic_version,
            },
        },
    };

    is_deeply( $tzil->distmeta->{prereqs}, $expected, q{non-core and core plugins are added to prereq} );
}
done_testing();

# vim: ts=4 sts=4 sw=4 et: syntax=perl
