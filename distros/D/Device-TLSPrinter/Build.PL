use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Device::TLSPrinter',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Device/TLSPrinter.pm',
    requires => {
        'Class::Accessor'   => '0.31',
        'IO'                => '1.23',
    },
    build_requires => {
        'Module::Build'     => '0.38',
        'Test::More'        => '0.70',
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/Device-TLSPrinter.git",
        }
    },
    add_to_cleanup      => [ 'Device-TLSPrinter-*' ],
);

$builder->create_build_script();
