use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Locale::Maketext::Lexicon::DBI',
    license           => 'perl',
    dist_author       => 'Matthias Dietrich <perl@rainboxx.de>',
    dist_version_from => 'lib/Locale/Maketext/Lexicon/DBI.pm',
    requires          => {
                  'Locale::Maketext::Lexicon' => 0,
                  'DBI'                       => 0,
                  'Test::More'                => 0,
                  'version'                   => 0,
                },
    add_to_cleanup     => ['Locale-Maketext-Lexicon-DBI-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
