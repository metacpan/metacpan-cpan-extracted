use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Copy::Vigilant',
    license             => 'perl',
    dist_author         => 'Anthony Kilna <anthony@kilna.com>',
    dist_version_from   => 'lib/File/Copy/Vigilant.pm',
    build_requires => {
        'Test::More'         => 0,
		# 'Test::Perl::Critic' => 0, # This is a huge dependency, and only really needed during development
		'File::Temp'         => 0,
		'IO::File'           => 0,
		'Data::Dumper'       => 0,
		'FindBin'            => 0,
    },
	requires => {
		'perl'              => '5.6.0',
		'File::Copy'        => 0,
		'File::Compare'     => 0,
		'Digest::MD5::File' => 0,
	},
    add_to_cleanup     => [ 'File-Copy-Vigilant-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
