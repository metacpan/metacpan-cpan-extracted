use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Kaiten::Container',
    license             => 'perl',
    dist_author         => q{Meettya <meettya@cpan.org>},
    dist_version_from   => 'lib/Kaiten/Container.pm',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More' => 0,
        'Test::Class' => 0,
        'Test::Warn' => 0,
        'Term::ANSIColor' => 0,
        'lib::abs' => 0,
        'DBI' => 0,
        'Moo' => 0,
        },
    requires => {
        'perl' => 5.010,
        'Moo'  => 0,
        'Scalar::Util' => 0,
        'Carp'  => 0,  
    },
    add_to_cleanup      => [ 'Kaiten-Container-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
    	resources => {
      		repository  => 'https://github.com/Meettya/Kaiten-Container/'
    	}
    }
);

$builder->create_build_script();
