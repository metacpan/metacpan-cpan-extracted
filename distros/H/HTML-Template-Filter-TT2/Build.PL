use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::Template::Filter::TT2',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/HTML/Template/Filter/TT2.pm',
    requires => {
        'HTML::Template' => 0,
    },
    build_requires => {
        'Test::More'     => 0,
    },
    add_to_cleanup      => [ 'HTML-Template-Filter-TT2-*' ],
);

$builder->create_build_script();
