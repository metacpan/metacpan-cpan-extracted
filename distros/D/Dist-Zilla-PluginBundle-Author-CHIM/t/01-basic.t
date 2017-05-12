#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.96;
use Path::Tiny;

use Test::DZil;

my $corpus = path('corpus/DZ')->absolute;

my $root_config = {
    name                => 'FooBarBaz',
    author              => 'John Doe <john@example.net>',
    license             => 'Perl_5',
    copyright_holder    => 'John Doe',
    copyright_year      => '2014',
    version             => '0.001',
};

my $tzil = Builder->from_config(
    {
        dist_root => "$corpus",
    },
    {
        add_files => {
            'source/dist.ini' => dist_ini(
                $root_config,
                [ '@Author::CHIM' => {
                        'dist'          => 'FooBarBaz',
                        'no_git'        => '1',
                        'github.user'   => 'john',
                        'github.repo'   => 'FooBarBaz-pm',
                    }
                ]
            ),
        },
    }
);

ok( $tzil->build, 'build dist with @Author::CHIM' );

my $meta = $tzil->distmeta;

is(
    $meta->{resources}{homepage},
    'https://metacpan.org/release/FooBarBaz',
    'homepage from META'
);

is(
    $meta->{resources}{repository}{url},
    'https://github.com/john/FooBarBaz-pm.git',
    'repository URL from META'
);

is(
    $meta->{abstract},
    'FooBarBaz module',
    'abstract from META'
);

is(
    ref $meta->{provides}{FooBarBaz},
    'HASH',
    'dist provides module'
);

done_testing;
