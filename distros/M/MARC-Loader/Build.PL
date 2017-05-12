use 5.010000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name           => 'MARC::Loader'
	, license             => 'perl'
	, dist_version_from   => 'lib/MARC/Loader.pm'
	, create_makefile_pl  => 'traditional'
    , dist_author         => 'Stephane Delaune <delaune.stephane@gmail.com>'
    , add_to_cleanup      => [ 'MARC-Loader-*' ]
    , requires => {qw<
	Scalar::Util 0
	MARC::Record 0
    >}
    , build_requires => {qw<
	Test::More 0
	Data::Compare 0
	YAML 0
    >}
);

$builder->create_build_script;
