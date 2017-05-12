use v5.10;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Graph::PetriNet',
    license             => 'perl',
    dist_author         => 'Robert Barta <rho@devc.at>',
    dist_version_from   => 'lib/Graph/PetriNet.pm',
    build_requires => {
	'Test::Pod::Coverage' => 0,
	'Test::Exception'     => 0,
	'Class::Trait'        => 0,
	'List::MoreUtils'     => 0,
	'Time::HiRes'         => 0,
    },
    add_to_cleanup      => [ 'Graph-PetriNet-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();



__END__



