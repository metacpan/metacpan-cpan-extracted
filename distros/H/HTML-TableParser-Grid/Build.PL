use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::TableParser::Grid',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/HTML/TableParser/Grid.pm',
    requires => {
        'version'    => 0,
        'HTML::TableParser' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
        'Test::Exception' => 0,
#        'Test::Perl::Critic' => 0,
#        'Test::Pod'            => 1.14,
#        'Test::Pod::Coverage'  => 1.04,
    },
    add_to_cleanup      => [ 'HTML-TableParser-Grid-*' ],
);

$builder->create_build_script();
