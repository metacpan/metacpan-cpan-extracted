use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Debug::Phases',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Debug/Phases.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Time::HiRes'=> 0,
    },
    add_to_cleanup      => [ 'Debug-Phases-*' ],
);

$builder->create_build_script();
