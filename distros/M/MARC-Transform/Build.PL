use 5.010000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name           => 'MARC::Transform'
	, license             => 'perl'
	, dist_version_from   => 'lib/MARC/Transform.pm'
	, create_makefile_pl  => 'traditional'
    , dist_author         => 'Stephane Delaune <delaune.stephane@gmail.com>'
    , add_to_cleanup      => [ 'MARC-Transform-*' ]
    , requires => {qw<
	Scalar::Util 0
	MARC::Record 0
    >}
    , build_requires => {qw<
	Test::More 0
	YAML 0
    >}
);

$builder->create_build_script;
