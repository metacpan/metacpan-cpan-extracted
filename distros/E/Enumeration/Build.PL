use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Enumeration',
    license             => 'perl',
    dist_author         => 'Eric J. Roode <roode@cpan.org>',
    dist_version_from   => 'lib/Enumeration.pm',
    build_requires => {
        'Test::More' => '0.10',
    },
    sign => 1,
    add_to_cleanup      => [ 'Enumeration-*' ],
);

$builder->create_build_script();
