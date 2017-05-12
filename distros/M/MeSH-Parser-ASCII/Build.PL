use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MeSH::Parser::ASCII',
    license             => 'gpl',
    dist_author         => q{Tomasz Adamusiak <tomasz@cpan.org>},
    dist_version_from => 'lib/MeSH/Parser/ASCII.pm',
    #dist_version => '0.01_02',
    dist_abstract => 'Parser for the MeSH ASCII format',
    build_requires => {
    	'Test::More' => 0,
    	'File::Temp' => 0,
    },
    requires => {
		'Moose' => '0.89',
		'Log::Log4perl' => 0,
    },
    #script_files        => ['scripts/similarity_match.pl'],
    add_to_cleanup      => [ 'MeSH-Parser-ASCII-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
