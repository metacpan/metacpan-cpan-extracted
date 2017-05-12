use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Tabular::Web',
    license             => 'perl',
    dist_author         => 'Laurent Dami <laurent.dami@justice.ge.ch>',
    dist_version_from   => 'lib/File/Tabular/Web.pm',
    requires => {
      'AppConfig'           => 0,
      'File::Basename'      => 0,
      'File::Path'          => 0,
      'File::Tabular'       => 0.71,
      'List::MoreUtils'     => 0,
      'List::Util'          => 0,
      'Plack::Component'    => 0,
      'Plack::Request'      => 0,
      'Plack::Response'     => 0,
      'POSIX'               => 0,
      'Scalar::Util'        => 0,
      'Search::QueryParser' => 0.92,
      'Template'            => 0,
      'Try::Tiny'           => 0,
    },
    test_requires => {
        'Test::More'       => 0,
    },
    recommends => {
      'Search::Indexer' => 0.75,
     },
    add_to_cleanup      => [ 'File-Tabular-Web-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/File-Tabular-Web',
       }
     },

);

$builder->create_build_script();


