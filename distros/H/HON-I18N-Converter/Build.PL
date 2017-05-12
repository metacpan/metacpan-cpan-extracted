use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HON::I18N::Converter',
    license             => 'perl',
    dist_author         => q{Samia Chahlal <samia.chahlal@yahoo.com>},
    dist_version_from   => 'lib/HON/I18N/Converter.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'      => 0.98,
        'Test::File'      => 1.35,
        'Test::Exception' => 0.31,
    },
    requires => {
        'File::Temp' => 0.22,
        'IO::All'    => 0.46,
        'Encode'     => 2.42_01,
        'JSON::XS'   => 2.33,
        'Carp'       => 1.26, 
        'Object::InsideOut' => 3.98,
        'Spreadsheet::ParseExcel' => 0.59,      
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/healthonnet/HON-I18N-Converter',
        },
    },
    add_to_cleanup     => [ 'HON-I18N-Converter-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
