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
    my $class     = 'Dist::Zilla::Plugin::Code::NameProvider';
    my $code_name = 'provide_name';

    use_ok( $class, "$class can be use'd" );

    note('Dist::Zilla::Role::PluginBundle');
    {
        my $prime = 1999;
        my $name  = 'MyName2017';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        { name => undef },
                        [
                            '=Local::PluginBundle::RetVal',
                            {
                                plugin => $class,
                                name   => $name,
                                code   => $code_name,
                                retval => "$name-$prime",
                            },
                        ],
                    ),
                },
            },
        );

        local $Local::PluginBundle::RetVal::RESULT;

        $tzil->build;

        is( $Local::PluginBundle::RetVal::RESULT, "$name-$prime", '... code did run' );
        is( ( scalar grep { $_ eq "[$name] Name = $name-$prime" } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle::Easy');
    {
        my $prime = 2003;
        my $name  = 'MyName2027';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        { name => undef },
                        [
                            '=Local::PluginBundleEasy::RetVal',
                            {
                                plugin => $class,
                                name   => $name,
                                code   => $code_name,
                                retval => "$name-$prime",
                            },
                        ],
                    ),
                },
            },
        );

        local $Local::PluginBundleEasy::RetVal::RESULT;

        $tzil->build;

        is( $Local::PluginBundleEasy::RetVal::RESULT, "$name-$prime", '... code did run' );
        is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy::RetVal/$name] Name = $name-$prime" } @{ $tzil->log_messages() } ), 1, '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName2029';

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
