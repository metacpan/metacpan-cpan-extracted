#!perl

use 5.006;
use strict;
use warnings;

use Test::DZil;
use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use lib 't/lib';

main();

sub main {
    my $class     = 'Dist::Zilla::Plugin::Code::BuildRunner';
    my $code_name = 'build';

    use_ok( $class, "$class can be use'd" );

    note('Dist::Zilla::Role::PluginBundle');
    {
        my $prime = 677;
        my $name  = 'MyName701';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [
                            '=Local::PluginBundle::BuildRunner',
                            {
                                plugin => $class,
                                input  => $prime,
                                name   => $name,
                                code   => $code_name,
                            },
                        ],
                    ),
                },
            },
        );

        local $Local::PluginBundle::BuildRunner::RESULT;

        $tzil->run_in_build( [ $^X, '-e', '1' ] );

        is( $Local::PluginBundle::BuildRunner::RESULT, $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[$name] $prime" } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle::Easy');
    {
        my $prime = 683;
        my $name  = 'MyName709';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [
                            '=Local::PluginBundleEasy::BuildRunner',
                            {
                                plugin => $class,
                                input  => $prime,
                                name   => $name,
                                code   => $code_name,
                            },
                        ],
                    ),
                },
            },
        );

        local $Local::PluginBundleEasy::BuildRunner::RESULT;

        $tzil->run_in_build( [ $^X, '-e', '1' ] );

        is( $Local::PluginBundleEasy::BuildRunner::RESULT, $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy::BuildRunner/$name] $prime" } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName719';

        my $e = exception {
            Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                '=Local::PluginBundleError',
                                {
                                    plugin => $class,
                                    name   => $name,
                                },
                            ],
                        ),
                    },
                },
            );
        };

        isnt( $e, undef, q{throws an exception if the code attribute isn't given} );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
