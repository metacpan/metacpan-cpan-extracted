use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Ingres::Utility::IINamu',
    license             => 'perl',
    dist_author         => 'Joner Cyrre Worm <FAJCNLXLLXIH@spammotel.com>',
    dist_version_from   => 'lib/Ingres/Utility/IINamu.pm',
    requires => {
        'Test::More' => 0,
        'Expect::Simple' => 0
    },
    add_to_cleanup      => [ 'Ingres-Utility-IINamu-*' ],
);

$builder->create_build_script();
