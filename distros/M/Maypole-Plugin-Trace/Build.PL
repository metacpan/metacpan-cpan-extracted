use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::Trace',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/Trace.pm',
    requires => {
        'Test::More' => 0,
        'Class::ISA' => 0,
        'Class::Inspector' => 0,
        'Data::Dumper' => 0,
        #'Text::Elide' => 0,
        'Class::Data::Inheritable' => 0,
        'NEXT' => 0,

    },
    add_to_cleanup      => [ 'Maypole-Plugin-Trace-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
