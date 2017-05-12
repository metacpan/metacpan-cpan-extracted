use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::KhatGallery::Plugin::SortNaturally',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/HTML/KhatGallery/Plugin/SortNaturally.pm',
	requires            => {
	     'HTML::KhatGallery' => 0,
	     'Sort::Naturally' => 0,
	},
    build_requires => {
        'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'HTML-KhatGallery-Plugin-SortNaturally-*' ],
);

$builder->create_build_script();
# create the Makefile.PL
use Module::Build::Compat;
print "creating Makefile.PL\n";
Module::Build::Compat->create_makefile_pl('passthrough', $builder);
