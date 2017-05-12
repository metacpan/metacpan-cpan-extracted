use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Launcher::Cascade',
    license             => 'perl',
    dist_author         => 'Cédric Bouvier <cbouvi@cpan.org>',
    dist_version_from   => 'lib/Launcher/Cascade.pm',
    build_requires => {
        'Test::More' => 0,
	'Log::Log4perl' => 0,
    },
    add_to_cleanup      => [ 'Launcher-Cascade-*' ],
);

$builder->create_build_script();
