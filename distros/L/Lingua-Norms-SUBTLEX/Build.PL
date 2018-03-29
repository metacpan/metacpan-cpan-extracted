use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Lingua::Norms::SUBTLEX',
    license            => 'perl',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Lingua/Norms/SUBTLEX.pm',
    dist_abstract =>
'Retrieve word frequencies and related values and lists from subtitles corpora',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4220',
    },
    build_requires => {
        'Array::Compare' => '2.012',
        'FindBin'        => '1.51',
        'Test::More'     => '1.302073',
    },
    requires => {
        'Config' => '5.020002',
        #'Encode' => '2.78',
        'English'              => '1.10',
        'File::RandomLine'     => '0.20',
        'File::Spec'           => '3.63_01',
        'Lingua::Orthon'       => '0.03',
        'List::AllUtils'       => '0.14',
        'Number::Misc'         => '1.2',
        'Path::Tiny'           => '0.104',
        'Readonly'             => '1.03',
        'Statistics::Lite'     => '3.62',
        'String::Trim'         => '0.005',
        'String::Util'         => '1.26',
        'Text::CSV::Hashify'   => '0.08',
        'Text::CSV::Separator' => '0.20',
        'Text::Unidecode'      => '1.30',
    },
    add_to_cleanup     => ['Lingua-Norms-SUBTLEX-0.06-*'],
    create_makefile_pl => 'traditional',
);
$builder->add_build_element('csv');
$builder->create_build_script();

1;