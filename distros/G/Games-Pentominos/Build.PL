use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Pentominos',
    license             => 'perl',
    dist_author         => 'Laurent Dami <laurent.dami@justice.ge.ch>',
    dist_version_from   => 'lib/Games/Pentominos.pm',
    requires => {
      'List::MoreUtils'  => 0,
     },
    build_requires => {
      'Test::More'   => 0,
    },
    add_to_cleanup      => [ 'Games-Pentominos-*' ],
);

$builder->create_build_script();
