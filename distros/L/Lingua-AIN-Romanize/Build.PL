use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::AIN::Romanize',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Lingua/AIN/Romanize.pm',
    requires => {
        'Test::Base'       => 0,
        'version'          => 0,
        'Lingua::JA::Kana' => '0.04',
    },
    auto_features => {
        'ain_setregex' => {
            description => "Set original convert table feature",
            requires    => {
                'Regexp::Assemble' => '0.34',
            },
        },
    },
    add_to_cleanup      => [ 'Lingua-AIN-Romanize-*' ],
);

$builder->create_build_script();
