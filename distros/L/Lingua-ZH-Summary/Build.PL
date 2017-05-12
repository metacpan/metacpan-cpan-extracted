use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::ZH::Summary',
    license             => 'perl',
    dist_author         => 'Cheng-Lung Sung <clsung@FreeBSD.org>',
    dist_version_from   => 'lib/Lingua/ZH/Summary.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Net::YASA' => 0,
    },
    add_to_cleanup      => [ 'Lingua-ZH-Summary-*' ],
);

$builder->create_build_script();
