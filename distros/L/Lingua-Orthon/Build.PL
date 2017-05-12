use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::Orthon',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from   => 'lib/Lingua/Orthon.pm',
    build_requires => {
        'Test::More' => '0.98',
        'List::AllUtils' => '0.03',
        'Math::MatrixReal' => '2.09',
        'String::LCSS_XS' => '1.2',
        'String::Similarity' => '1.04',
        'Text::Abbrev' => '1.01',
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Lingua-Orthon-0.02-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
