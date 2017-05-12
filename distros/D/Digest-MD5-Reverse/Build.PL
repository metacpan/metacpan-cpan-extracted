use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Digest::MD5::Reverse',
    license             => 'perl',
    dist_author         => 'Urma Raoul-Gabriel <blwood@skynet.be>',
    dist_abstract       => 'MD5 Reverse Lookup',
    dist_version_from   => 'lib/Digest/MD5/Reverse.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Digest-MD5-Reverse-*' ],
);

$builder->create_build_script();
