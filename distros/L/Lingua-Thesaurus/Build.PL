use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::Thesaurus',
    license             => 'perl',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/Lingua/Thesaurus.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        perl                => 5.010,
        'Carp'              => 0,
        'Moose'             => 0,
        'Module::Load'      => 0,
        'namespace::clean'  => 0,
        'DBI'               => 0,
        'DBD::SQLite'       => 1.54,
        'Search::Tokenizer' => 0,
    },
    test_requires => {
        'POSIX' => 0,
    },
    add_to_cleanup     => [ 'Lingua-Thesaurus-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Lingua-Thesaurus',
       }
     },

);

$builder->create_build_script();
