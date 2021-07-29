#!perl

use 5.006;
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::DZil;
use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use lib 't/lib';

main();

sub main {
    my $class = 'Dist::Zilla::PluginBundle::Code';

    use_ok( $class, "$class can be use'd" );

    note('Dist::Zilla::Role::PluginBundle');
    {
        my $prime = 41;
        my $name  = 'MyName43';

        local $Local::PluginBundle::Bundle::RESULT;

        my ( $stdout, $tzil ) = capture_stdout {
            Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                '=Local::PluginBundle::Bundle',
                                {
                                    bundle => $class,
                                    input  => $prime,
                                    name   => $name,
                                },
                            ],
                        ),
                    },
                },
            );
        };

        $tzil->build;

        is( $Local::PluginBundle::Bundle::RESULT, $prime * $prime,                '... code did run' );
        is( $stdout,                              ">>$prime<<\n}}A${prime}Z{{\n", '... correct message got logged' );
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName47';

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
