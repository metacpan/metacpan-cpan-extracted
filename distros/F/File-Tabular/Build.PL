use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Tabular',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/File/Tabular.pm',
    requires => {
        'Hash::Type'          => '1.0',
        'Search::QueryParser' => '0.92',
        'File::Temp'          => 0,
        'Carp'                => 0,
        'Fcntl'               => 0,
    },
    configure_requires => {
        'Module::Build'       => 0,
     },
    add_to_cleanup      => [ 'File-Tabular-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/File-Tabular',
       }
     },
);

$builder->create_build_script();



