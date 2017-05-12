use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::TreeBuilder::Select',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/HTML/TreeBuilder/Select.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    	'HTML::TreeBuilder' => 0,
    	'HTML::TreeBuilder::XPath' => 0,
    	'HTML::Selector::XPath' => 0,
    	'Class::Accessor' => 0,
    	'Carp' => 0,
    },
    add_to_cleanup      => [ 'HTML-TreeBuilder-Select-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
