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
    my $class     = 'Dist::Zilla::Plugin::Code::NameProvider';
    my $code_name = 'provide_name';

    use_ok($class);

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

        is( $Local::PluginBundle::RetVal::RESULT,                                               "$name-$prime", '... code did run' );
        is( ( scalar grep { $_ eq "[$name] Name = $name-$prime" } @{ $tzil->log_messages() } ), 1,              '... correct message got logged' )
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

        is( $Local::PluginBundleEasy::RetVal::RESULT,                                                                            "$name-$prime", '... code did run' );
        is( ( scalar grep { $_ eq "[=Local::PluginBundleEasy::RetVal/$name] Name = $name-$prime" } @{ $tzil->log_messages() } ), 1,              '... correct message got logged' )
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
