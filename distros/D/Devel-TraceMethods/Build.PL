use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::TraceMethods',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@wgz.org>',
    dist_version_from   => 'lib/Devel/TraceMethods.pm',
	requires            =>
	{
	},
    build_requires      =>
	{
        'Test::Simple'  => '0.60',
    },
	create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
