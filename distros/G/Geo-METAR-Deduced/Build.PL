use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'Geo::METAR::Deduced',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'perl'                   => '5.16.0',
        'Class::Measure::Scientific::FX_992vb' => 0,
        'Data::Dumper'           => 0,
        'English'                => 0,
        'Geo::ICAO'              => 0,
        'Geo::METAR'             => 0,
        'Log::Log4perl'          => 0,
        'Moose'                  => 0,
        'MooseX::NonMoose'       => 0,
        'Readonly'               => 1.03,
        'Set::Scalar'            => 0,
    },
    build_requires => {
        'Test::More'       => 0.86,
        'Test::NoWarnings' => 0,
    },
    test_requires => {},
    sign          => 1,
)->create_build_script;
