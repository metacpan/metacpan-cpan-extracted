use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Font::TTF::OpenTypeLigatures',
    license             => 'Perl',
    dist_author         => q{Simon Cozens <simon@cpan.org>},
    dist_version_from   => 'lib/Font/TTF/OpenTypeLigatures.pm',
    build_requires => {
        'Font::TTF::Font' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Font-TTF-OpenTypeLigatures-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
