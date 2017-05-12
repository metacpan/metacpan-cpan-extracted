use strict;
use warnings FATAL => 'all';

use Test::More;

use List::Util qw/min/;
use Path::Tiny;
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;

require Dist::Zilla; # for VERSION

my $dz_version = min( 5, int( Dist::Zilla->VERSION ) );

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir             => ],
                [ MetaJSON              => ],
                [ 'Prereqs::AuthorDeps' => { relation => 'recommends' } ],
              )
              . "\n\n; authordep Devel::Foo = 0.123\n",
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->build;
my $json = path( $tzil->tempdir, qw(build META.json) )->slurp_raw;

cmp_deeply(
    $json,
    json(
        superhashof(
            {
                dynamic_config => 0,
                prereqs        => {
                    develop => {
                        recommends => {
                            'Devel::Foo'                               => 0.123,
                            'Dist::Zilla'                              => $dz_version,
                            'Dist::Zilla::Plugin::GatherDir'           => 0,
                            'Dist::Zilla::Plugin::MetaJSON'            => 0,
                            'Dist::Zilla::Plugin::Prereqs::AuthorDeps' => 0,
                            (
                                eval { Dist::Zilla->VERSION(5.038); 1 } ? ( 'Software::License::Perl_5' => 0 ) : ()
                            )
                        },
                    },
                },
            }
        )
    ),
    'authordeps added as develop recommends',
);

done_testing;
#
# This file is part of Dist-Zilla-Plugin-Prereqs-AuthorDeps
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
