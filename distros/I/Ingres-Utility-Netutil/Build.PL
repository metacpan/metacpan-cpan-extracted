use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Ingres::Utility::Netutil',
    license             => 'perl',
    dist_author         => 'Joner Cyrre Worm <FAJCNLXLLXIH@spammotel.com>',
    dist_version_from   => 'lib/Ingres/Utility/Netutil.pm',
    requires => {
        'Carp'          => 0,
        'Expect::Simple'=> 0,
        'Test::More'    => 0
    },
    add_to_cleanup      => [ 'Ingres-Utility-Netutil-*' ],
);

$builder->create_build_script();
