use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Log::Dispatch::Configurator::Perl',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Log/Dispatch/Configurator/Perl.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.6.2',
        'parent' => 0,
        'Carp' => 0,
        'Log::Dispatch::Configurator' => 0,
    },
    add_to_cleanup      => [ 'Log-Dispatch-Configurator-Perl-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Log-Dispatch-Configurator-Perl'
      }
    },
);

$builder->create_build_script();
