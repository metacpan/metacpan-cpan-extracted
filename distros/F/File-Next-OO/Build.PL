use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Next::OO',
    license             => 'perl',
    dist_author         => 'Boris Zentner <bzm@2bz.de>',
    dist_version_from   => 'lib/File/Next/OO.pm',
    requires => {
        'Test::More' => 0,
	'File::Next' => 0.28,
#        'version'    => 0,
    },
    add_to_cleanup      => [ 'File-Next-OO-*' ],
);

$builder->create_build_script();
