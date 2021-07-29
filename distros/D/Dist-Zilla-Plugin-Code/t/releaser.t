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
    my $class     = 'Dist::Zilla::Plugin::Code::Releaser';
    my $code_name = 'release';

    use_ok( $class, "$class can be use'd" );

    note('Dist::Zilla::Role::PluginBundle');
    {
        my $prime = 2309;
        my $name  = 'MyName2339';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [
                            '=Local::PluginBundle',
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

        local $Local::PluginBundle::RESULT;

        $tzil->release;

        is( $Local::PluginBundle::RESULT,                                          $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle::Easy');
    {
        my $prime = 2311;
        my $name  = 'MyName2341';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [
                            '=Local::PluginBundleEasy',
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

        local $Local::PluginBundleEasy::RESULT;

        $tzil->release;

        is( $Local::PluginBundleEasy::RESULT,                                                               $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy/$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName2347';

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
