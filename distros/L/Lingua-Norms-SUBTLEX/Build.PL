use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Lingua::Norms::SUBTLEX',
    license            => 'perl',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Lingua/Norms/SUBTLEX.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.421',
    },
    build_requires => {
        'Array::Compare' => '2.11',
        'FindBin'        => '1.51',
        'Test::More'     => '0.98',
    },
    requires => {
        'Config'               => 0,
        'English'              => '1.05',
        'File::RandomLine'     => '0.20',
        'File::Slurp'          => '9999.19',
        'File::Spec'           => '3.40',
        'Lingua::Orthon'       => '0.01',
        'Readonly'             => '1.03',
        'Statistics::Lite'     => '3.6',
        'String::Util'         => '1.24',
        'Text::CSV::Separator' => '0.20',
    },
    add_to_cleanup     => ['Lingua-Norms-SUBTLEX-0.04-*'],
    create_makefile_pl => 'traditional',
);
$builder->add_build_element('csv');
$builder->create_build_script();
