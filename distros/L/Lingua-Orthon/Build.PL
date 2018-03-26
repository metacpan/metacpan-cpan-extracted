use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Lingua::Orthon',
    license           => 'perl_5',
    dist_author       => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from => 'lib/Lingua/Orthon.pm',
    dist_abstract =>
'Orthographic similarity of strings - Coltheart\'s N and related measures',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4220',
    },
    build_requires => {
        'Test::More' => '1.302073',
    },
    requires => {
        'List::AllUtils'        => '0.14',
        'Number::Misc'          => '1.2',
        'Statistics::Lite'      => '3.62',
        'String::Util'          => '1.26',
        'Text::Levenshtein'     => '0.13',
        'Text::Levenshtein::XS' => '0.503',
        'Unicode::Collate'      => '1.19',
    },
    add_to_cleanup     => ['Lingua-Orthon-0.03-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;
