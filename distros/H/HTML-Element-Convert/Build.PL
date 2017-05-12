use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::Element::Convert',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/HTML/Element/Convert.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    	'HTML::TreeBuilder' => 0,
	'Carp' => 0,
    },
    optional => {
    	'Text::Markdown' => 0,
    	'JSON' => 0,
    	'YAML' => 0,
    },
    add_to_cleanup      => [ 'HTML-Element-Convert-*' ],
);

$builder->create_build_script();
