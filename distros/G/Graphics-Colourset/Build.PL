use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Graphics::Colourset',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/Graphics/Colourset.pm',
	requires            => {
	'Getopt::Long' => 2.34,
	'Pod::Usage' => 0,
	'Getopt::ArgvFile' => 1.09,
	'Graphics::ColorObject' => 0,
	},
    build_requires => {
        'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'Graphics-Colourset-*' ],
    script_files => [qw(scripts/colourset)],
    meta_add => {
        resources  => {
            repository  => 'git://github.com/rubykat/Graphics-Colourset.git',
            homepage  => 'http://github.com/rubykat/Graphics-Colourset',
        },
    },
);

$builder->create_build_script();
