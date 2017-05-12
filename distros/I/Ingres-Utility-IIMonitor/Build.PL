use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Ingres::Utility::IIMonitor',
    license             => 'perl',
    dist_author         => 'Joner Cyrre Worm <FAJCNLXLLXIH@spammotel.com>',
    dist_version_from   => 'lib/Ingres/Utility/IIMonitor.pm',
    requires => {
        'Test::More' => 0,
        'Expect::Simple' => 0
    },
    add_to_cleanup      => [ 'Ingres-Utility-IIMonitor-*' ],
);

$builder->create_build_script();
