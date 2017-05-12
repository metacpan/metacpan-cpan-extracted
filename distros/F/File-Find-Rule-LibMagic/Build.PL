use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Find::Rule::LibMagic',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/File/Find/Rule/LibMagic.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
	'File::Find::Rule' => 0.30,
	'File::LibMagic' => 0.96,
	'Params::Util' => 1.00,
	'Text::Glob' => 0,
    },
    conflicts => {
	'File::Find::Rule::MMagic' => 0,
    },
    meta_merge => {
	no_index => {
	    directory => [ qw(t/samples) ],
	},
    },
    add_to_cleanup      => [ 'File-Find-Rule-LibMagic-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
