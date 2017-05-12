use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Email::Send::SMTP::TLS',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Email/Send/SMTP/TLS.pm',
    build_requires => {
        'Test::More' => 0,
        'Email::Send' => 0,
        'Email::Address' => 0,
        'Return::Value'  => 0,
        'Net::SMTP::TLS::ButMaintained' => 0,
    },
    add_to_cleanup      => [ 'Email-Send-SMTP-TLS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
