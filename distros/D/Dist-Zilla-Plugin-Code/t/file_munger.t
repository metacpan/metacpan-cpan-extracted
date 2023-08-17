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

main();

sub main {
    my $class = 'Dist::Zilla::Plugin::Code::FileMunger';

    use_ok($class);

    for my $code_name (qw(munge_file munge_files)) {

        note("$class ($code_name)");
        {
            my $prime = $code_name eq 'munge_file' ? 1237         : 5281;
            my $name  = $code_name eq 'munge_file' ? 'MyName1277' : 'MyName1278';

            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            'GatherDir',
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

            $tzil->build;

            is( $Local::PluginBundle::RESULT,                                          $prime * $prime, '... code did run' );
            is( ( scalar grep { $_ eq "[$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note("$class ($code_name)");
        {
            my $prime = $code_name eq 'munge_file' ? 1249         : 5297;
            my $name  = $code_name eq 'munge_file' ? 'MyName1279' : 'MyName1280';

            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            'GatherDir',
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

            $tzil->build;

            is( $Local::PluginBundleEasy::RESULT,                                                               $prime * $prime, '... code did run' );
            is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy/$name] $prime" } @{ $tzil->log_messages() } ), 1,               '... correct message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }
    }

    note('Dist::Zilla::Role::PluginBundle (wrong usage)');
    {
        my $name = 'MyName1283';

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

        like( $e, qr{^\QAttribute (munge_file) or (munge_files) is required at constructor\E}xsm, q{throws an exception if neither the munge_file nor the munge_files attribute isn't given} );
    }

    done_testing();

    exit 0;
}
