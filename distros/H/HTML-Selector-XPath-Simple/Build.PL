use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::Selector::XPath::Simple',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/HTML/Selector/XPath/Simple.pm',
    requires => {
        'version'                  => 0,
	'HTML::Selector::XPath'    => 0,
	'HTML::TreeBuilder::XPath' => 0,
    },
    build_requires => {
        'Test::More'           => 0,
        'Test::NoWarnings'     => 0,
#        'Test::Perl::Critic'   => 0,
#        'Test::Pod'            => 1.14,
#        'Test::Pod::Coverage'  => 1.04,
    },
    add_to_cleanup      => [ 'HTML-Selector-XPath-Simple-*' ],
);

$builder->create_build_script();
