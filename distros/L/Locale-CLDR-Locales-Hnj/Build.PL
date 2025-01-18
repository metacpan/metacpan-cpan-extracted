use strict;
use warnings;
use utf8;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Locale::CLDR::Locales::Hnj',
    license             => 'perl',
    requires        => {
        'version'                   => '0.95',
        'DateTime'                  => '0.72',
        'Moo'                       => '2',
        'MooX::ClassAttribute'      => '0.011',
        'Type::Tiny'                => 0,
        'perl'                      => '5.12.0',
        'Locale::CLDR'              => '0.46.0',
    },
    dist_author         => q{John Imrie <john.imrie1@gmail.com>},
    dist_version_from   => 'lib/Locale/CLDR/Locales/Hnj.pm',
    build_requires => {
        'ok'                => 0,
        'Test::Exception'   => 0,
        'Test::More'        => '0.98',
    },
    add_to_cleanup      => [ 'Locale-CLDR-Locales-Hnj-*' ],
    configure_requires => { 'Module::Build' => '0.40' },
    release_status => 'stable',
    dist_abstract => q<Locale::CLDR - Data Package ( Perl localization data for Hmong Njua )>,
    meta_add => {
        keywords => [ qw( locale CLDR locale-data-pack ) ],
        resources => {
            homepage => 'https://github.com/ThePilgrim/perlcldr',
            bugtracker => 'https://github.com/ThePilgrim/perlcldr/issues',
            repository => 'https://github.com/ThePilgrim/perlcldr.git',
        },
    },
);

$builder->create_build_script();
