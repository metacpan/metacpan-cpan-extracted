#!perl

use 5.006;
use strict;
use warnings;

use Test::DZil;
use Test::More 0.88;
use Test::TempDir::Tiny;

use lib 't/lib';

main();

sub main {
    note('Dist::Zilla::Role::PluginBundle');
    {
        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        '=Local::PluginBundle',
                        [ '=Local::PluginBundle', 'AnotherName' ],
                    ),
                },
            },
        );

        $tzil->build;

        is( ( scalar grep { $_ eq '[=Local::PluginBundle] Hello from Local::PluginBundle: name => =Local::PluginBundle' } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;

        is( ( scalar grep { $_ eq '[AnotherName] Hello from Local::PluginBundle: name => AnotherName' } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle::Easy');
    {
        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        '=Local::PluginBundleEasy',
                        [ '=Local::PluginBundleEasy', 'AnotherName2' ],
                    ),
                },
            },
        );

        $tzil->build;

        is( ( scalar grep { $_ eq '[=Local::PluginBundleEasy] Hello from Local::PluginBundleEasy: name => =Local::PluginBundleEasy' } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;

        is( ( scalar grep { $_ eq '[AnotherName2] Hello from Local::PluginBundleEasy: name => AnotherName2' } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
