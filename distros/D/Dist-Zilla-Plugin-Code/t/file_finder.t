#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2020-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::DZil;
use Test::Fatal;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use Dist::Zilla::File::InMemory;

main();

sub main {
    my $class     = 'Dist::Zilla::Plugin::Code::FileFinder';
    my $code_name = 'find_files';

    use_ok($class);

    note('Dist::Zilla::Role::PluginBundle');
    {
        my $prime = 967;
        my $name  = 'MyName983';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        'GatherDir',
                        [
                            '=Local::PluginBundle::FileConsumer',
                            {
                                plugin => $class,
                                input  => $prime,
                                name   => $name,
                                code   => $code_name,
                            },
                        ],
                    ),
                    "source/lib/file-1-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-1-${prime}.pm", content => q{} ),
                    "source/lib/file-2-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-2-${prime}.pm", content => q{} ),
                    "source/lib/file-3-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-3-${prime}.pm", content => q{} ),
                },
            },
        );

        local $Local::PluginBundle::FileConsumer::RESULT;
        local $Local::FileConsumer::RESULT;

        $tzil->build;

        is( $Local::PluginBundle::FileConsumer::RESULT,                            $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;

        is_deeply( $Local::FileConsumer::RESULT, [ "lib/file-2-${prime}.pm", "lib/file-3-${prime}.pm" ], '... correct files were found' );
    }

    note('Dist::Zilla::Role::PluginBundle::Easy');
    {
        my $prime = 971;
        my $name  = 'MyName991';

        my $tzil = Builder->from_config(
            { dist_root => tempdir() },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        'GatherDir',
                        [
                            '=Local::PluginBundleEasy::FileConsumer',
                            {
                                plugin => $class,
                                input  => $prime,
                                name   => $name,
                                code   => $code_name,
                            },
                        ],
                    ),
                    "source/lib/file-1-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-1-${prime}.pm", content => q{} ),
                    "source/lib/file-2-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-2-${prime}.pm", content => q{} ),
                    "source/lib/file-3-${prime}.pm" => Dist::Zilla::File::InMemory->new( name => "lib/file-3-${prime}.pm", content => q{} ),
                },
            },
        );

        local $Local::PluginBundleEasy::FileConsumer::RESULT;
        local $Local::FileConsumer::RESULT;

        $tzil->build;

        is( $Local::PluginBundleEasy::FileConsumer::RESULT,                                                               $prime * $prime, '... code did run' );
        is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy::FileConsumer/$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
          or diag 'got log messages: ', explain $tzil->log_messages;

        is_deeply( $Local::FileConsumer::RESULT, [ "lib/file-1-${prime}.pm", "lib/file-3-${prime}.pm" ], '... correct files were found' );
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName997';

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
