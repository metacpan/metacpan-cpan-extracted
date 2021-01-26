use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'Geo::METAR::Deduced',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'Class::Measure::Scientific::FX_992vb' => 0,
        'English'                              => 0,
        'Geo::ICAO'                            => 0,
        'Geo::METAR'                           => 0,
        'Moose'                                => 0,
        'MooseX::NonMoose'                     => 0,
        'Readonly'                             => 1.03,
        'Set::Scalar'                          => 0,
        'perl'                                 => '5.16.0',
        'strict'                               => 0,
        'utf8'                                 => 0,
        'warnings'                             => 0,
    },
    configure_requires => { 'Module::Build' => 0.40, },
    build_requires     => { 'Module::Build' => 0.40, },
    test_requires      => {
        'Test::More'       => 0.86,
        'Test::NoWarnings' => 0,
        'Test::Warn'       => 0,
    },
    meta_merge => {
        resources => {
            repository =>
              'https://bitbucket.org/rolandvanipenburg/geo-metar-deduced',
            bugtracker =>
'https://bitbucket.org/rolandvanipenburg/geo-metar-deduced/issues',
        },
    },
    sign => 1,
)->create_build_script;
