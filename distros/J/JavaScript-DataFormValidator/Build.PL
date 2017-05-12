use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'JavaScript::DataFormValidator',
    license             => 'perl',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    dist_version_from   => 'lib/JavaScript/DataFormValidator.pm',
    build_requires => {
        'Test::More'             => 0,
        'Data::JavaScript::Anon' => 0,
    },
    create_makefile_pl   => 'traditional',
    create_readme       => 1,
    add_to_cleanup      => [ 'JavaScript-DataFormValidator-*' ],
);

$builder->create_build_script();
