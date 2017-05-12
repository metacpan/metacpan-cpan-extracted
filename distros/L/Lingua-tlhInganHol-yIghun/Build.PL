#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::tlhInganHol::yIghun',
    license             => 'perl',
    dist_author         => 'Michael G Schwern <schwern@pobox.com>',
    dist_version_from   => 'lib/Lingua/tlhInganHol/yIghun.pm',

    build_requires => {
        'Test::More'    => '0.47',
        'Test::Harness' => 3
    },
    requires => {       
        'Filter::Simple'        => '0.84',
        perl                    => '5.8.1',
    },

    add_to_cleanup      => [ 'Lingua-tlhInganHol-yIghun-*' ],

    meta_merge => {
        resources => {
            homepage   => "http://search.cpan.org/dist/Lingua-tlhInganHol-yIghun",
            repository => "http://github.com/schwern/lingua-tlhinganhol-yighun/tree/master",
            bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-tlhInganHol-yIghun",
        }
    },

    meta_add => {
        author => [
            'Damian Conway <dconway@cpan.org>',
            'Michael G Schwern <schwern@pobox.com>',
        ]
    },
);

$builder->create_build_script();
