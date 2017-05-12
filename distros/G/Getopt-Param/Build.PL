use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Getopt::Param',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Getopt/Param.pm',
    requires => {
        'Test::More'               => 0,
        'version'                  => 0,
        'Locale::Maketext::Pseudo' => 0,
        'Class::Std'               => 0,
        'Class::Std::Utils'        => 0,
    },
    add_to_cleanup      => [ 'Getopt-Param-*' ],
);

$builder->create_build_script();
