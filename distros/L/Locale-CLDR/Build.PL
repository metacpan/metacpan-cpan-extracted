use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Locale::CLDR',
    license             => 'perl',
    requires        => {
        'version'                   => '0.95',
        'DateTime'                  => '0.72',
        'Moo'                       => '2',
        'MooX::ClassAttribute'      => '0.011',
        'perl'                      => '5.10.1',
        'Type::Tiny'                => 0,
        'Class::Load'               => 0,
        'DateTime::Locale'          => 0,
        'namespace::autoclean'      => 0.16,
        'List::MoreUtils'           => 0,
        'Unicode::Regex::Set'       => 0,
        'bigfloat'                  => 0,
    },
    dist_author         => q{John Imrie <john.imrie1@gmail.com>},
    dist_version_from   => 'lib/Locale/CLDR.pm',
    build_requires => {
        'ok'                => 0,
        'Test::Exception'   => 0,
        'Test::More'        => '0.98',
        'File::Spec'        => 0,
    },
    add_to_cleanup      => [ 'Locale-CLDR-*' ],
    configure_requires => { 'Module::Build' => '0.40' },
    release_status => 'stable',
    meta_add => {
        keywords => [ qw( locale CLDR ) ],
        resources => {
            homepage => 'https://github.com/ThePilgrim/perlcldr',
            bugtracker => 'https://github.com/ThePilgrim/perlcldr/issues',
            repository => 'https://github.com/ThePilgrim/perlcldr.git',
        },
    },
);

$builder->create_build_script();
